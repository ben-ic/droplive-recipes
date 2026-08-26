# Catalogue verification

A recipe is reviewed runtime intent and creates a candidate. A passing build or
probe is not proof that an application is ready for the public catalogue.

## Listing gate

List a version only after a reviewer completes all of these checks through the
public launch UI:

1. Start the exact recipe and source version that will be listed.
2. Confirm that the launch page shows every required username, password,
   database value, setup value, or first-run instruction.
3. Complete login or setup with only that information.
4. Reach a useful application screen. A health response, loading page, login
   page, empty error page, or process-running probe is not sufficient.
5. Complete one safe product action when the application supports it.
6. Save one secret-free screenshot of the useful screen.
7. End the demo through the public UI.

If any check fails, keep the version unlisted. Fix the recipe first unless the
evidence proves a generic platform defect.

The session TTL starts when the application becomes live. Startup must not use
the reviewer's live time.

The recipe declaration is authoritative for the visitor description and
canonical repository identity. The forge refresher can update changing forge
facts only.

## Screenshot evidence

Keep the screenshot with the browser-review record. Do not commit it to this
recipe source repository. Use a useful dashboard, editor, library, document
view, or completed first-run screen. Do not capture a password, API key,
credential card, loading state, error, or filled login form.

## Catalogue reconciliation

The public catalogue and this repository must describe the same product. At a
catalogue checkpoint, record or verify for every visible app:

- the exact recipe version and source version;
- browser-verification status;
- login and first-run guidance;
- emulator and BYOK behavior;
- the browser-review evidence.

An unfinished recipe can remain in this repository as an unlisted candidate.
A visible app must use the current verified recipe contract.
