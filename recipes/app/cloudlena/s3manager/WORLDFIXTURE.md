# S3 Manager with WorldFixture

This recipe replaces the unfinished Metabase candidate in the five-app release at the user's request. It reuses the Filestash S3 launcher that passed Firecracker review.

The pinned WorldFixture CLI runs `up --only s3 --no-rebase --setup` inside the same guest as S3 Manager. The launcher waits for generated bindings and passes them directly to S3 Manager. No S3 key is shown to the visitor. The temporary DropLive session opens the native bucket browser without setup.

The image contains the S3 provider and its pinned company dataset. The emulator keeps writes within this disposable guest. The launcher stops the app if the provider fails. Source dates are preserved. No Metabase process, Java runtime, or PostgreSQL service is included.

Validation is pending. Required browser check: list the populated buckets, open a populated folder, download a file or upload and read back a synthetic file, save a secret-free screenshot, and end the public session. Build readiness alone does not permit listing.
