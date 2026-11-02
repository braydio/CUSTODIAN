#!/usr/bin/env python3
"""
Index CUSTODIAN/design into a ChromaDB collection using local Ollama embeddings.

Examples:
    python custodian_chroma.py index
    python custodian_chroma.py index ~/Projects/CUSTODIAN/custodian/design
    python custodian_chroma.py index --force
    python custodian_chroma.py search "What did I decide about the first terminal objective?"
    python custodian_chroma.py stats

Environment variables:
    CHROMA_HOST=127.0.0.1
    CHROMA_PORT=8055
    CHROMA_SSL=false
    CHROMA_COLLECTION=custodian_design
    OLLAMA_URL=http://127.0.0.1:11434
    OLLAMA_EMBED_MODEL=embeddinggemma
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any, Iterable, Iterator, Sequence

try:
    import chromadb
except ImportError:
    print(
        "Missing dependency: chromadb-client\n"
        "Install it with:\n"
        "  python -m pip install chromadb-client",
        file=sys.stderr,
    )
    raise SystemExit(2)


TEXT_EXTENSIONS = {
    ".md", ".markdown", ".txt", ".rst", ".adoc",
    ".json", ".jsonc", ".yaml", ".yml", ".toml", ".ini", ".cfg",
    ".csv", ".tsv", ".xml",
    ".gd", ".gdshader", ".tscn", ".tres", ".godot",
    ".py", ".lua", ".sql",
    ".js", ".jsx", ".ts", ".tsx",
    ".html", ".htm", ".css", ".scss",
    ".sh", ".bash", ".zsh", ".fish",
}

SKIP_DIRECTORIES = {
    ".git", ".godot", ".idea", ".vscode",
    ".venv", "venv", "__pycache__",
    "node_modules", "dist", "build", "cache", "tmp", "temp",
}

DEFAULT_MAX_FILE_BYTES = 5 * 1024 * 1024
DEFAULT_CHUNK_CHARS = 1800
DEFAULT_OVERLAP_CHARS = 250
DEFAULT_BATCH_SIZE = 24


def env_bool(name: str, default: bool = False) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def resolve_default_root() -> Path:
    candidates = [
        Path.home() / "Projects" / "CUSTODIAN" / "custodian" / "design",
        Path.home() / "Projects" / "CUSTODIAN" / "design",
    ]
    for candidate in candidates:
        if candidate.is_dir():
            return candidate
    return candidates[0]


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def batched(items: Sequence[Any], batch_size: int) -> Iterator[Sequence[Any]]:
    for start in range(0, len(items), batch_size):
        yield items[start : start + batch_size]


def read_text_file(path: Path, max_file_bytes: int) -> tuple[str, bytes]:
    size = path.stat().st_size
    if size > max_file_bytes:
        raise ValueError(
            f"file is {size / (1024 * 1024):.1f} MiB; "
            f"limit is {max_file_bytes / (1024 * 1024):.1f} MiB"
        )

    raw = path.read_bytes()

    if b"\x00" in raw[:8192]:
        raise ValueError("appears to be binary")

    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        text = raw.decode("utf-8", errors="replace")

    text = text.replace("\r\n", "\n").replace("\r", "\n")
    return text, raw


def choose_chunk_end(text: str, start: int, tentative_end: int) -> int:
    """Prefer a natural boundary near the end of a character window."""
    if tentative_end >= len(text):
        return len(text)

    minimum = start + max(1, (tentative_end - start) // 2)
    window = text[minimum:tentative_end]

    candidates: list[int] = []
    for marker in ("\n\n", "\n# ", "\n## ", "\n", ". ", "; ", ", ", " "):
        position = window.rfind(marker)
        if position >= 0:
            candidates.append(minimum + position + len(marker))

    return max(candidates) if candidates else tentative_end


def chunk_text(text: str, max_chars: int, overlap_chars: int) -> list[str]:
    if max_chars < 200:
        raise ValueError("--chunk-chars must be at least 200")
    if overlap_chars < 0 or overlap_chars >= max_chars:
        raise ValueError("--overlap-chars must be >= 0 and smaller than --chunk-chars")

    cleaned = "\n".join(line.rstrip() for line in text.splitlines()).strip()
    if not cleaned:
        return []

    chunks: list[str] = []
    start = 0

    while start < len(cleaned):
        tentative_end = min(start + max_chars, len(cleaned))
        end = choose_chunk_end(cleaned, start, tentative_end)
        if end <= start:
            end = tentative_end

        chunk = cleaned[start:end].strip()
        if chunk:
            chunks.append(chunk)

        if end >= len(cleaned):
            break

        next_start = max(0, end - overlap_chars)
        if next_start <= start:
            next_start = end
        start = next_start

    return chunks


def iter_source_files(root: Path) -> Iterator[Path]:
    for current_root, directories, filenames in os.walk(root):
        directories[:] = sorted(
            directory
            for directory in directories
            if directory not in SKIP_DIRECTORIES
            and not directory.startswith(".")
        )

        base = Path(current_root)
        for filename in sorted(filenames):
            path = base / filename
            if path.is_symlink():
                continue
            if path.suffix.lower() in TEXT_EXTENSIONS:
                yield path


def ollama_embed(
    texts: Sequence[str],
    base_url: str,
    model: str,
    timeout_seconds: int = 300,
) -> list[list[float]]:
    if not texts:
        return []

    endpoint = f"{base_url.rstrip('/')}/api/embed"
    payload = json.dumps(
        {
            "model": model,
            "input": list(texts),
            "truncate": True,
            "keep_alive": "10m",
        }
    ).encode("utf-8")

    request = urllib.request.Request(
        endpoint,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
            body = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(
            f"Ollama embedding request failed with HTTP {exc.code}: {detail}\n"
            f"Confirm the model exists with: ollama pull {model}"
        ) from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(
            f"Could not reach Ollama at {endpoint}: {exc.reason}"
        ) from exc

    embeddings = body.get("embeddings")
    if not isinstance(embeddings, list) or len(embeddings) != len(texts):
        raise RuntimeError(
            f"Ollama returned {len(embeddings or [])} embeddings "
            f"for {len(texts)} inputs"
        )

    return embeddings


def make_client(args: argparse.Namespace):
    client = chromadb.HttpClient(
        host=args.chroma_host,
        port=args.chroma_port,
        ssl=args.chroma_ssl,
    )
    try:
        client.heartbeat()
    except Exception as exc:
        scheme = "https" if args.chroma_ssl else "http"
        raise RuntimeError(
            f"Could not reach ChromaDB at "
            f"{scheme}://{args.chroma_host}:{args.chroma_port}"
        ) from exc
    return client


def get_collection(client: Any, name: str):
    """
    Use the current Chroma configuration format, with a compatibility fallback
    for older Chroma servers/clients.
    """
    try:
        return client.get_or_create_collection(
            name=name,
            configuration={"hnsw": {"space": "cosine"}},
        )
    except (TypeError, ValueError):
        return client.get_or_create_collection(
            name=name,
            metadata={"hnsw:space": "cosine"},
        )


def file_where(root_id: str, source: str) -> dict[str, Any]:
    return {
        "$and": [
            {"root_id": {"$eq": root_id}},
            {"source": {"$eq": source}},
        ]
    }


def get_all_records(
    collection: Any,
    *,
    where: dict[str, Any] | None = None,
    include: list[str] | None = None,
    page_size: int = 1000,
) -> dict[str, list[Any]]:
    include = include or ["metadatas"]
    combined: dict[str, list[Any]] = {"ids": []}
    for key in include:
        combined[key] = []

    offset = 0
    while True:
        result = collection.get(
            where=where,
            limit=page_size,
            offset=offset,
            include=include,
        )
        ids = list(result.get("ids") or [])
        if not ids:
            break

        combined["ids"].extend(ids)
        for key in include:
            combined[key].extend(list(result.get(key) or []))

        if len(ids) < page_size:
            break
        offset += len(ids)

    return combined


def ensure_embedding_model_compatible(collection: Any, model: str) -> None:
    if collection.count() == 0:
        return

    sample = collection.get(limit=1, include=["metadatas"])
    metadatas = sample.get("metadatas") or []
    if not metadatas:
        return

    existing_model = (metadatas[0] or {}).get("embedding_model")
    if existing_model and existing_model != model:
        raise RuntimeError(
            f"Collection already contains embeddings from {existing_model!r}, "
            f"but this run requested {model!r}. Embedding models must not be "
            f"mixed in one collection. Use a different --collection name."
        )


def existing_file_records(
    collection: Any,
    root_id: str,
    source: str,
) -> dict[str, list[Any]]:
    return get_all_records(
        collection,
        where=file_where(root_id, source),
        include=["metadatas"],
    )


def metadata_matches(
    metadatas: Sequence[dict[str, Any] | None],
    *,
    file_hash: str,
    model: str,
    chunk_chars: int,
    overlap_chars: int,
) -> bool:
    if not metadatas:
        return False

    for metadata in metadatas:
        metadata = metadata or {}
        if (
            metadata.get("file_sha256") != file_hash
            or metadata.get("embedding_model") != model
            or metadata.get("chunk_chars") != chunk_chars
            or metadata.get("overlap_chars") != overlap_chars
        ):
            return False
    return True


def index_directory(args: argparse.Namespace) -> int:
    root = Path(args.directory).expanduser().resolve()
    if not root.is_dir():
        raise RuntimeError(f"Directory does not exist: {root}")

    root_id = sha256_bytes(str(root).encode("utf-8"))[:20]
    client = make_client(args)
    collection = get_collection(client, args.collection)
    ensure_embedding_model_compatible(collection, args.ollama_model)

    files = list(iter_source_files(root))
    current_sources: set[str] = set()

    indexed_files = 0
    skipped_files = 0
    failed_files = 0
    indexed_chunks = 0

    print(f"Root:       {root}")
    print(f"Collection: {args.collection}")
    print(f"ChromaDB:   {args.chroma_host}:{args.chroma_port}")
    print(f"Ollama:     {args.ollama_url}")
    print(f"Model:      {args.ollama_model}")
    print(f"Files:      {len(files)} candidate text files")
    print()

    for number, path in enumerate(files, start=1):
        source = path.relative_to(root).as_posix()
        current_sources.add(source)

        try:
            text, raw = read_text_file(path, args.max_file_bytes)
            file_hash = sha256_bytes(raw)
            chunks = chunk_text(text, args.chunk_chars, args.overlap_chars)
            existing = existing_file_records(collection, root_id, source)
            existing_ids = set(existing["ids"])

            if not chunks:
                if existing_ids:
                    collection.delete(ids=list(existing_ids))
                print(f"[{number:>4}/{len(files)}] EMPTY   {source}")
                skipped_files += 1
                continue

            if (
                not args.force
                and existing_ids
                and metadata_matches(
                    existing.get("metadatas") or [],
                    file_hash=file_hash,
                    model=args.ollama_model,
                    chunk_chars=args.chunk_chars,
                    overlap_chars=args.overlap_chars,
                )
            ):
                print(
                    f"[{number:>4}/{len(files)}] SKIP    "
                    f"{source} ({len(existing_ids)} chunks)"
                )
                skipped_files += 1
                continue

            documents = [
                f"SOURCE: {source}\n\n{chunk}"
                for chunk in chunks
            ]
            ids = [
                hashlib.sha256(
                    f"{root_id}\0{source}\0{index}\0{chunk}".encode("utf-8")
                ).hexdigest()
                for index, chunk in enumerate(chunks)
            ]

            stat = path.stat()
            metadatas = [
                {
                    "root": str(root),
                    "root_id": root_id,
                    "source": source,
                    "filename": path.name,
                    "extension": path.suffix.lower(),
                    "chunk_index": index,
                    "chunk_count": len(chunks),
                    "file_sha256": file_hash,
                    "mtime_ns": int(stat.st_mtime_ns),
                    "size_bytes": int(stat.st_size),
                    "embedding_model": args.ollama_model,
                    "chunk_chars": args.chunk_chars,
                    "overlap_chars": args.overlap_chars,
                }
                for index in range(len(chunks))
            ]

            new_id_set = set(ids)

            for batch_start in range(0, len(documents), args.batch_size):
                batch_end = min(batch_start + args.batch_size, len(documents))
                batch_documents = documents[batch_start:batch_end]
                batch_ids = ids[batch_start:batch_end]
                batch_metadatas = metadatas[batch_start:batch_end]

                embeddings = ollama_embed(
                    batch_documents,
                    args.ollama_url,
                    args.ollama_model,
                    args.ollama_timeout,
                )

                collection.upsert(
                    ids=batch_ids,
                    documents=batch_documents,
                    metadatas=batch_metadatas,
                    embeddings=embeddings,
                )

            stale_ids = existing_ids - new_id_set
            if stale_ids:
                collection.delete(ids=list(stale_ids))

            indexed_files += 1
            indexed_chunks += len(chunks)
            print(
                f"[{number:>4}/{len(files)}] INDEX   "
                f"{source} ({len(chunks)} chunks)"
            )

        except Exception as exc:
            failed_files += 1
            print(
                f"[{number:>4}/{len(files)}] ERROR   {source}: {exc}",
                file=sys.stderr,
            )
            if args.fail_fast:
                raise

    pruned_sources = 0
    if not args.no_prune:
        all_existing = get_all_records(
            collection,
            where={"root_id": {"$eq": root_id}},
            include=["metadatas"],
        )
        existing_sources = {
            metadata.get("source")
            for metadata in (all_existing.get("metadatas") or [])
            if metadata and metadata.get("source")
        }

        for stale_source in sorted(existing_sources - current_sources):
            collection.delete(where=file_where(root_id, stale_source))
            pruned_sources += 1
            print(f"PRUNE   {stale_source}")

    print()
    print(
        f"Done: {indexed_files} indexed, {skipped_files} unchanged/empty, "
        f"{failed_files} failed, {indexed_chunks} chunks written, "
        f"{pruned_sources} deleted-file sources pruned."
    )
    print(f"Collection now contains {collection.count()} records.")

    return 1 if failed_files else 0


def search_collection(args: argparse.Namespace) -> int:
    root = Path(args.root).expanduser().resolve()
    root_id = sha256_bytes(str(root).encode("utf-8"))[:20]

    client = make_client(args)
    collection = get_collection(client, args.collection)
    ensure_embedding_model_compatible(collection, args.ollama_model)

    if collection.count() == 0:
        print("The collection is empty. Run the index command first.")
        return 1

    query_embedding = ollama_embed(
        [args.query],
        args.ollama_url,
        args.ollama_model,
        args.ollama_timeout,
    )[0]

    result = collection.query(
        query_embeddings=[query_embedding],
        n_results=args.limit,
        where={"root_id": {"$eq": root_id}},
        include=["documents", "metadatas", "distances"],
    )

    ids = (result.get("ids") or [[]])[0]
    documents = (result.get("documents") or [[]])[0]
    metadatas = (result.get("metadatas") or [[]])[0]
    distances = (result.get("distances") or [[]])[0]

    if not ids:
        print(f"No indexed records found for root: {root}")
        return 1

    for rank, (document, metadata, distance) in enumerate(
        zip(documents, metadatas, distances),
        start=1,
    ):
        metadata = metadata or {}
        source = metadata.get("source", "unknown")
        chunk_index = int(metadata.get("chunk_index", 0)) + 1
        chunk_count = int(metadata.get("chunk_count", 1))

        print(f"\n[{rank}] {source} — chunk {chunk_index}/{chunk_count}")
        print(f"    cosine distance: {distance:.4f}")
        print("-" * 80)
        print(document)
        print("-" * 80)

    return 0


def show_stats(args: argparse.Namespace) -> int:
    root = Path(args.root).expanduser().resolve()
    root_id = sha256_bytes(str(root).encode("utf-8"))[:20]

    client = make_client(args)
    collection = get_collection(client, args.collection)
    records = get_all_records(
        collection,
        where={"root_id": {"$eq": root_id}},
        include=["metadatas"],
    )

    metadatas = records.get("metadatas") or []
    sources = {
        metadata.get("source")
        for metadata in metadatas
        if metadata and metadata.get("source")
    }

    print(f"Collection:    {args.collection}")
    print(f"Root:          {root}")
    print(f"Indexed files: {len(sources)}")
    print(f"Indexed chunks:{len(records.get('ids') or [])}")
    print(f"All records:   {collection.count()}")
    return 0


def add_connection_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--chroma-host",
        default=os.getenv("CHROMA_HOST", "127.0.0.1"),
    )
    parser.add_argument(
        "--chroma-port",
        type=int,
        default=int(os.getenv("CHROMA_PORT", "8055")),
    )
    parser.add_argument(
        "--chroma-ssl",
        action="store_true",
        default=env_bool("CHROMA_SSL", False),
    )
    parser.add_argument(
        "--collection",
        default=os.getenv("CHROMA_COLLECTION", "custodian_design"),
    )
    parser.add_argument(
        "--ollama-url",
        default=os.getenv("OLLAMA_URL", "http://127.0.0.1:11434"),
    )
    parser.add_argument(
        "--ollama-model",
        default=os.getenv("OLLAMA_EMBED_MODEL", "embeddinggemma"),
    )
    parser.add_argument(
        "--ollama-timeout",
        type=int,
        default=300,
    )


def build_parser() -> argparse.ArgumentParser:
    default_root = resolve_default_root()

    parser = argparse.ArgumentParser(
        description="Index and search CUSTODIAN design files with ChromaDB + Ollama."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    index_parser = subparsers.add_parser(
        "index",
        help="Recursively index a design directory.",
    )
    add_connection_arguments(index_parser)
    index_parser.add_argument(
        "directory",
        nargs="?",
        default=str(default_root),
        help=f"Directory to index (default: {default_root})",
    )
    index_parser.add_argument(
        "--chunk-chars",
        type=int,
        default=DEFAULT_CHUNK_CHARS,
    )
    index_parser.add_argument(
        "--overlap-chars",
        type=int,
        default=DEFAULT_OVERLAP_CHARS,
    )
    index_parser.add_argument(
        "--batch-size",
        type=int,
        default=DEFAULT_BATCH_SIZE,
    )
    index_parser.add_argument(
        "--max-file-mib",
        type=float,
        default=DEFAULT_MAX_FILE_BYTES / (1024 * 1024),
        help="Skip individual files larger than this size.",
    )
    index_parser.add_argument(
        "--force",
        action="store_true",
        help="Re-embed files even when their content and settings are unchanged.",
    )
    index_parser.add_argument(
        "--no-prune",
        action="store_true",
        help="Do not remove indexed records for files deleted from the directory.",
    )
    index_parser.add_argument(
        "--fail-fast",
        action="store_true",
        help="Stop immediately when a file fails instead of continuing.",
    )

    search_parser = subparsers.add_parser(
        "search",
        help="Run a semantic search against the indexed directory.",
    )
    add_connection_arguments(search_parser)
    search_parser.add_argument("query")
    search_parser.add_argument(
        "--root",
        default=str(default_root),
        help=f"Indexed root to filter by (default: {default_root})",
    )
    search_parser.add_argument(
        "-n", "--limit",
        type=int,
        default=8,
    )

    stats_parser = subparsers.add_parser(
        "stats",
        help="Show record counts for the indexed directory.",
    )
    add_connection_arguments(stats_parser)
    stats_parser.add_argument(
        "--root",
        default=str(default_root),
        help=f"Indexed root to inspect (default: {default_root})",
    )

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.command == "index":
        args.max_file_bytes = int(args.max_file_mib * 1024 * 1024)
        return index_directory(args)
    if args.command == "search":
        return search_collection(args)
    if args.command == "stats":
        return show_stats(args)

    parser.error(f"Unknown command: {args.command}")
    return 2


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("\nCancelled.", file=sys.stderr)
        raise SystemExit(130)
    except Exception as exc:
        print(f"Fatal: {exc}", file=sys.stderr)
        raise SystemExit(1)

