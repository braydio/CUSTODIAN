from __future__ import annotations

from collections import deque
from dataclasses import dataclass
import hashlib
import json
from pathlib import Path
import random
import re
from typing import Any


TOKEN_RE = re.compile(r"#([^#]+)#")


def stable_hash64(text: str) -> int:
    """Return a deterministic 64-bit hash for stable seed mixing."""
    digest = hashlib.blake2b(text.encode("utf-8"), digest_size=8).digest()
    return int.from_bytes(digest, "little", signed=False)


def mix_seed64(*parts: Any) -> int:
    """Combine parts into a deterministic 64-bit seed."""
    joined = "|".join(str(part) for part in parts)
    return stable_hash64(joined)


def _apply_modifier(text: str, modifier: str) -> str:
    mod = modifier.strip().lower()
    if not mod:
        return text
    if mod == "upper":
        return text.upper()
    if mod == "lower":
        return text.lower()
    if mod == "capitalize":
        return text[:1].upper() + text[1:]
    if mod == "a":
        if not text.strip():
            return text
        first_word = text.strip().split(" ", 1)[0].lower()
        article = "an" if first_word[:1] in {"a", "e", "i", "o", "u"} else "a"
        return f"{article} {text}"
    return text


@dataclass(frozen=True)
class Variant:
    text: str
    weight: int = 1

    @staticmethod
    def from_json(obj: Any) -> "Variant":
        if isinstance(obj, str):
            return Variant(text=obj, weight=1)
        if not isinstance(obj, dict):
            raise TypeError("variant must be string or object")
        text = str(obj.get("text", ""))
        weight = max(1, int(obj.get("weight", 1)))
        return Variant(text=text, weight=weight)


class VariantMemory:
    """Track recent variants per symbol to avoid immediate repeats."""

    def __init__(self, max_recent: int = 3):
        self.max_recent = max(1, int(max_recent))
        self._recent: dict[str, deque[str]] = {}

    def record(self, key: str, chosen_text: str) -> None:
        history = self._recent.get(key)
        if history is None:
            history = deque(maxlen=self.max_recent)
            self._recent[key] = history
        history.append(chosen_text)

    def is_recent(self, key: str, candidate_text: str) -> bool:
        history = self._recent.get(key)
        if not history:
            return False
        return candidate_text in history


@dataclass(frozen=True)
class GrammarBank:
    version: int
    symbols: dict[str, list[Variant]]

    def variants_for(self, symbol: str) -> list[Variant]:
        return self.symbols.get(symbol, [])


def load_grammar_bank(path: Path) -> GrammarBank:
    data = json.loads(path.read_text(encoding="utf-8"))
    version = int(data.get("version", 1))
    raw_symbols = data.get("symbols", {})
    if not isinstance(raw_symbols, dict):
        raise TypeError("symbols must be an object")
    symbols: dict[str, list[Variant]] = {}
    for key, values in raw_symbols.items():
        if not isinstance(values, list):
            continue
        symbols[str(key)] = [Variant.from_json(value) for value in values]
    return GrammarBank(version=version, symbols=symbols)


class GrammarEngine:
    """Deterministic grammar expander with weighted variant selection."""

    def __init__(self, bank: GrammarBank, *, max_depth: int = 12):
        self.bank = bank
        self.max_depth = max(1, int(max_depth))

    @staticmethod
    def _weighted_choice(variants: list[Variant], rng: random.Random) -> Variant:
        total = sum(variant.weight for variant in variants)
        pick = rng.randint(1, max(1, total))
        running = 0
        for variant in variants:
            running += variant.weight
            if pick <= running:
                return variant
        return variants[-1]

    def _choose_variant(
        self,
        symbol: str,
        variants: list[Variant],
        rng: random.Random,
        memory: VariantMemory | None,
    ) -> Variant | None:
        if not variants:
            return None
        if len(variants) == 1 or memory is None:
            return self._weighted_choice(variants, rng)
        non_recent = [value for value in variants if not memory.is_recent(symbol, value.text)]
        return self._weighted_choice(non_recent or variants, rng)

    def render(
        self,
        symbol: str,
        *,
        context: dict[str, str] | None = None,
        seed: int = 0,
        salt: str = "",
        memory: VariantMemory | None = None,
    ) -> str:
        rng = random.Random(mix_seed64(seed, symbol, salt))
        variant = self._choose_variant(symbol, self.bank.variants_for(symbol), rng, memory)
        if variant is None:
            return ""
        if memory is not None:
            memory.record(symbol, variant.text)
        return self._expand_text(
            variant.text,
            context=dict(context or {}),
            seed=seed,
            salt=salt,
            memory=memory,
            depth=0,
        )

    def _expand_text(
        self,
        text: str,
        *,
        context: dict[str, str],
        seed: int,
        salt: str,
        memory: VariantMemory | None,
        depth: int,
    ) -> str:
        if depth >= self.max_depth:
            return text

        def _replace(match: re.Match[str]) -> str:
            token = match.group(1).strip()
            if not token:
                return ""
            parts = token.split(".")
            base = parts[0]
            modifiers = parts[1:]
            if base in context:
                output = context[base]
            else:
                output = self.render(
                    base,
                    context=context,
                    seed=seed,
                    salt=f"{salt}|{base}|d{depth}",
                    memory=memory,
                )
            for modifier in modifiers:
                output = _apply_modifier(output, modifier)
            return output

        expanded = TOKEN_RE.sub(_replace, text)
        if "#" not in expanded:
            return expanded
        return self._expand_text(
            expanded,
            context=context,
            seed=seed,
            salt=salt,
            memory=memory,
            depth=depth + 1,
        )
