# Common Vaultwing source art

The regenerated South/North strips replaced the temporary matte-bearing
baseline on 2026-09-23. They retain the same semantic source filenames and
256px frame contracts. Future corrected art can replace these files through the
same normal Asset V2 workflow:

1. preserve the replacement candidate under this source-work directory;
2. stage matching `state__direction.png` files in
   `custodian/asset_drop/inbox/ambient_vaultwing_common/`;
3. run `asset.py plan ambient_vaultwing_common` and inspect the dry-run;
4. apply the targeted family ingest with replacement enabled where required;
5. run Vaultwing and changed-file validation.

The original matte-bearing inputs remain preserved under
`custodian/asset_drop/unresolved/ambient_vaultwing_south_north_20260922/` as
rollback and comparison evidence. Do not delete that quarantine when replacing
these temporary strips.
