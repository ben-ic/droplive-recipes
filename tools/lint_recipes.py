#!/usr/bin/env python3
"""Validate public DropLive recipes."""

from __future__ import annotations

import ipaddress
import json
import re
import sys
from pathlib import Path
from typing import Any

import yaml
from jsonschema import Draft202012Validator


ROOT = Path(__file__).resolve().parents[1]
RECIPES = ROOT / "recipes"
SCHEMA = ROOT / "schema/droplive.recipe.v1.schema.json"
CAPABILITIES = ROOT / "capabilities/v1.yaml"
COMPANIONS = ROOT / "companions/v1.yaml"

EXPECTED_HOST = re.compile(
    r"^(?:\*\.)?(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+"
    r"[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?$"
)
RUNTIME_VALUE = re.compile(r"\{\{([A-Z_][A-Z0-9_]*)\}\}")

# A recipe entrypoint is a declaration surface, not only code, and until now
# nothing checked it. Every rule below is a mistake that reached main and was
# found by launching the application instead.
REQUIRED_VALUE = re.compile(r"\$\{([A-Z_][A-Z0-9_]*):\?")
BOOTSTRAP_ANNOTATION = re.compile(
    r"(?mi)^[ \t]*#[ \t]*droplive:[ \t]*generate=hex(?:64|96)[ \t]+"
    r"ownership=app[ \t]+purpose=(?P<purpose>owner|admin)-bootstrap[ \t]+"
    r"lifecycle=stable[ \t]+rotation=(?:app|none)[ \t]+"
    r"name=(?P<name>[A-Z_][A-Z0-9_]*)"
    r"(?:[ \t]+capability=(?P<capability>(?:owner|admin)-login))?"
    r"(?:[ \t]+username=[A-Za-z0-9_.@+-]{1,128})?"
    r"[ \t]*$"
)
ANNOTATION_LINE = re.compile(r"(?mi)^[ \t]*#[ \t]*droplive:.*$")
CREDENTIAL_WORD = re.compile(r"(?:^|_)(?:PASSWORD|PASS|SECRET|TOKEN)(?:_|$)")
# An exact-length assertion on a generated value. The platform never promised a
# length, so this rejects a longer and perfectly usable value -- and it exits
# before the process binds a port, so it reads as a broken application.
EXACT_LENGTH_TEST = re.compile(
    r"(?m)(?:\[\[?[^\n]*|test[^\n]*)"
    r"(?:\$\{#[A-Z_][A-Z0-9_]*\}|\$\{?#?[a-z_][a-z0-9_]*_length\}?)"
    r"[^\n]*-ne[ \t]+[0-9]+"
)
DATA_LAYER_WORD = re.compile(
    r"(?:^|_)(?:DB|DATABASE|POSTGRES|POSTGRESQL|MYSQL|MARIADB|MONGO|MONGODB|"
    r"REDIS|VALKEY|UPSTASH)(?:_|$)"
)
ORIGIN_EXACT = frozenset({"APP_URL", "AUTH_URL", "NEXTAUTH_URL", "ROOT_URL"})
ORIGIN_SUFFIX = re.compile(r"(?:^|_)(?:ROOT_URL|SITE_URL|BASE_URL|PUBLIC_URL)$")


def is_public_origin_name(name: str) -> bool:
    """Names DropLive fills with the session origin, so a recipe must not."""

    upper = name.upper()
    if DATA_LAYER_WORD.search(upper):
        return False
    return upper in ORIGIN_EXACT or bool(ORIGIN_SUFFIX.search(upper))


def location(parts: list[Any]) -> str:
    return ".".join(str(part) for part in parts) or "root"


def dockerfile_errors(
    path: Path, run: dict[str, Any], require_network_probe: bool = True
) -> list[str]:
    errors: list[str] = []
    stages: set[str] = set()
    has_expose = False
    has_healthcheck = False

    for number, raw in enumerate(path.read_text(errors="replace").splitlines(), 1):
        line = raw.strip()
        if re.match(r"(?i)^EXPOSE\s", line):
            has_expose = True
        if re.match(r"(?i)^HEALTHCHECK\s", line):
            has_healthcheck = True
        if not re.match(r"(?i)^FROM\s", line):
            continue
        parts = [part for part in line.split()[1:] if not part.startswith("--")]
        reference = parts[0] if parts else ""
        if reference != "scratch" and reference not in stages and "@sha256:" not in reference:
            errors.append(f"{path.name}:{number}: FROM is not digest-pinned: {reference}")
        if len(parts) >= 3 and parts[1].lower() == "as":
            stages.add(parts[2])

    if require_network_probe and not has_expose and "port" not in run:
        errors.append("add EXPOSE to Dockerfile or add run.port to droplive.yaml")
    if require_network_probe and not has_healthcheck and "health" not in run:
        errors.append("add HEALTHCHECK to Dockerfile or add run.health to droplive.yaml")
    return errors


def compose_errors(
    path: Path,
    service_name: str | None,
    run: dict[str, Any],
    require_network_probe: bool = True,
    kind: str | None = None,
) -> list[str]:
    try:
        document = yaml.safe_load(path.read_text())
    except yaml.YAMLError as exc:
        return [f"docker-compose.yaml is not valid YAML: {exc}"]

    services = document.get("services") if isinstance(document, dict) else None
    if not isinstance(services, dict) or not services:
        return ["docker-compose.yaml must contain at least one service"]

    if service_name is None:
        if "app" in services:
            service_name = "app"
        elif len(services) == 1:
            service_name = next(iter(services))
        else:
            return ["docker-compose.yaml has multiple services; add build.service"]

    service = services.get(service_name)
    if not isinstance(service, dict):
        return [f"docker-compose.yaml has no service named {service_name}"]

    errors: list[str] = []
    # An application gets its own writable copy-on-write root, populated from the
    # image, so a read-only root is no longer something to ask for -- it is the
    # thing the workarounds in these recipes existed to survive. An MCP or
    # emulator container has no such need and keeps it.
    if kind in ("mcp", "skill"):
        if service.get("read_only") is not True:
            errors.append(f"service {service_name} must set read_only: true")
    elif service.get("read_only") is True:
        errors.append(
            f"service {service_name} sets read_only: true, but an application is "
            "given a writable root filesystem; remove it and the workarounds it forced"
        )
    if (
        require_network_probe
        and "port" not in run
        and not service.get("ports")
        and not service.get("expose")
    ):
        errors.append(f"service {service_name} must expose a port or droplive.yaml must set run.port")
    if require_network_probe and "health" not in run and not service.get("healthcheck"):
        errors.append(f"service {service_name} needs a healthcheck or droplive.yaml must set run.health")
    image = service.get("image")
    if image and not service.get("build") and "@sha256:" not in str(image):
        errors.append(f"service {service_name} image is not digest-pinned: {image}")
    return errors


def build_errors(recipe_file: Path, recipe: dict[str, Any]) -> list[str]:
    folder = recipe_file.parent
    build = recipe.get("build") or {}
    run = recipe.get("run") or {}
    local_compose = folder / "docker-compose.yaml"
    local_dockerfile = folder / "Dockerfile"
    require_network_probe = not (
        recipe.get("kind") == "mcp"
        and (recipe.get("mcp") or {}).get("transport") == "stdio"
    )

    if build.get("docker-compose") or build.get("dockerfile") or build.get("image"):
        return []
    if local_compose.is_file():
        return compose_errors(
            local_compose,
            build.get("service"),
            run,
            require_network_probe,
            recipe.get("kind"),
        )
    if local_dockerfile.is_file():
        return dockerfile_errors(local_dockerfile, run, require_network_probe)
    if build.get("service"):
        return ["build.service requires docker-compose.yaml or build.docker-compose"]
    return []


def managed_data_errors(recipe_file: Path, recipe: dict[str, Any]) -> list[str]:
    """A managed-data backup label needs the paths that it must archive."""

    dockerfile = recipe_file.parent / "Dockerfile"
    if not dockerfile.is_file() or "io.droplive.data-backup" not in dockerfile.read_text(
        errors="replace"
    ):
        return []
    if (recipe.get("run") or {}).get("data"):
        return []
    return ["Dockerfile has io.droplive.data-backup but run.data is empty"]


def world_errors(recipe: dict[str, Any], capabilities: dict[str, Any]) -> list[str]:
    """A demo that already holds its world names it at the top level.

    There is no capability to validate it against -- that is the point of the
    field -- so it is checked against the same reviewed ids an emulator dataset
    may select. A world nothing has published is a typo, and a typo here means a
    demo that silently claims to be stocked and is not.
    """
    declared = recipe.get("world")
    if declared is None:
        return []
    reviewed = {
        dataset
        for definition in capabilities.values()
        for dataset in (definition.get("datasets") or [])
    }
    if declared not in reviewed:
        return [f"world {declared} has no reviewed publication"]
    return []


def capability_errors(recipe: dict[str, Any], capabilities: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    for name, emulator in (recipe.get("emulators") or {}).items():
        capability_id = emulator["capability"]
        definition = capabilities.get(capability_id)
        if definition is None:
            errors.append(f"emulator {name} uses unknown capability {capability_id}")
            continue
        access = emulator.get("access", "server")
        if access not in definition["access"]:
            errors.append(f"capability {capability_id} does not support access {access}")
        for environment_name, output in emulator["bindings"].items():
            if output not in definition["outputs"]:
                errors.append(f"capability {capability_id} has no output {output} for {environment_name}")
        if emulator.get("byok") is True:
            if capability_id != "llm.openai_chat.v1":
                errors.append(f"emulator {name} enables BYOK for unsupported capability {capability_id}")
            else:
                # Both halves, or neither. A recipe that offers the visitor's own
                # key while leaving the base URL bound to the emulator sends that
                # key to a fixture which ignores it, and the demo presents
                # generated replies as the real provider's. DropLive refuses such
                # a group at build and at launch; saying so here means the author
                # finds out while editing the recipe.
                bound = set(emulator["bindings"].values())
                for output in ("api_base_url", "non_authenticating_api_key"):
                    if output not in bound:
                        errors.append(
                            f"emulator {name} enables BYOK and must bind {output}: "
                            "the provider endpoint and credential are replaced together"
                        )
        dataset = emulator.get("dataset")
        if dataset and dataset not in definition["datasets"]:
            errors.append(f"capability {capability_id} does not support dataset {dataset}")
        errors.extend(seed_errors(name, emulator))
    return errors


def companion_errors(recipe: dict[str, Any], companions: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    for name, companion in (recipe.get("companions") or {}).items():
        if isinstance(companion, str):
            continue
        companion_type = companion["type"]
        definition = companions.get(companion_type)
        if definition is None:
            errors.append(f"companion {name} uses unknown type {companion_type}")
            continue
        dataset = companion.get("dataset")
        if dataset and dataset not in definition["datasets"]:
            errors.append(f"companion {companion_type} does not support dataset {dataset}")
        for environment_name, output in companion["bindings"].items():
            if output not in definition["outputs"]:
                errors.append(
                    f"companion {companion_type} has no output {output} for {environment_name}"
                )
    return errors


# Keys that carry an identity or a credential. A recipe may layer CONTENT over a
# dataset -- messages, files, repositories, customers -- but not the identities that
# content belongs to.
#
# The reason is not policy, it is that a half-supplied identity does not fail loudly.
# The emulator resolves a caller's token against the vendor's own store, so a user the
# recipe invents has no token and every authenticated call answers 401. A recipe cannot
# see the dataset's tokens to match one, so it cannot get this right even in principle.
IDENTITY_KEYS = frozenset(
    {
        "users",
        "tokens",
        "oauth_clients",
        "oauth_apps",
        "oauth_applications",
        "api_keys",
        "account",
        "integrations",
        "database_users",
        "iam",
    }
)


def seed_errors(name: str, emulator: dict[str, Any]) -> list[str]:
    seed = emulator.get("seed")
    if not seed:
        return []

    errors = [
        f"emulator {name} seed cannot declare {key}; identities and credentials come "
        f"from the reviewed dataset"
        for key in sorted(set(seed) & IDENTITY_KEYS)
    ]

    if not emulator.get("dataset"):
        errors.append(f"emulator {name} declares seed without a dataset to layer it over")

    return errors


def mcp_errors(recipe: dict[str, Any], recipe_file: Path | None = None) -> list[str]:
    if recipe.get("kind") != "mcp":
        return []

    mcp = recipe["mcp"]
    tools = mcp.get("tools") or {}
    smoke = tools.get("smoke") or {}
    errors: list[str] = []

    expected_hosts = mcp.get("expected_hosts") or []
    if mcp["network"] == "none" and expected_hosts:
        errors.append("MCP expected_hosts is not allowed when network is none")
    for host in expected_hosts:
        candidate = host.removeprefix("*.")
        try:
            ipaddress.ip_address(candidate)
        except ValueError:
            pass
        else:
            errors.append(f"MCP expected host must not be an IP address: {host}")
            continue
        if not EXPECTED_HOST.fullmatch(host):
            errors.append(
                "MCP expected host must be a hostname or wildcard hostname, "
                f"not a URL, address, port, path, or credential: {host}"
            )

    if mcp["transport"] == "stdio" and mcp.get("command"):
        command = mcp["command"]
        forbidden = {"bash", "curl", "env", "npx", "pip", "sh", "sudo", "uvx", "wget"}
        executable = Path(command[0]).name.lower()
        if executable in forbidden:
            errors.append(
                f"MCP command must run the resolved package executable directly, not {executable}"
            )
        if any("\x00" in argument for argument in command):
            errors.append("MCP command arguments cannot contain NUL")

        declared_values = set((recipe.get("environment") or {}).keys())
        for dependency in (recipe.get("emulators") or {}).values():
            declared_values.update(dependency.get("bindings") or {})
        for dependency in (recipe.get("companions") or {}).values():
            if isinstance(dependency, dict):
                declared_values.update(dependency.get("bindings") or {})
        for argument in command:
            runtime_value = RUNTIME_VALUE.fullmatch(argument)
            if "{{" in argument or "}}" in argument:
                if runtime_value is None:
                    errors.append(
                        "MCP runtime value must be one complete command argument: "
                        f"{argument}"
                    )
                    continue
                if runtime_value.group(1) not in declared_values:
                    errors.append(
                        "MCP command uses undeclared runtime value "
                        f"{runtime_value.group(1)}"
                    )

    if mcp.get("package") and not mcp.get("command"):
        errors.append("MCP package build path requires a resolved command")

    if not smoke:
        errors.append("MCP tools must include one smoke call")
    elif len(json.dumps(smoke["arguments"], separators=(",", ":")).encode()) > 16384:
        errors.append("MCP smoke arguments must be at most 16384 encoded bytes")

    if mcp.get("package") and recipe.get("build"):
        errors.append("MCP package and source build paths cannot be mixed")
    if mcp.get("package") and recipe_file:
        folder = recipe_file.parent
        local_build_files = [
            name
            for name in ("Dockerfile", "docker-compose.yaml")
            if (folder / name).is_file()
        ]
        if local_build_files:
            errors.append(
                "MCP package and recipe-owned source build paths cannot be mixed: "
                + ", ".join(local_build_files)
            )

    return errors


def entrypoint_errors(recipe_file: Path, recipe: dict[str, Any]) -> list[str]:
    """Check what a recipe declares outside `droplive.yaml`.

    The entrypoint states which values are required and which are generated
    bootstrap credentials, so a mistake here is a mistake in the recipe's
    contract -- it just used to surface as a container that never bound a port.
    """

    errors: list[str] = []
    environment = recipe.get("environment") or {}

    for name, spec in environment.items():
        if not isinstance(spec, dict):
            continue
        if spec.get("owner") == "droplive" and is_public_origin_name(name):
            errors.append(
                f"{name} is an origin-shaped name, which DropLive already fills "
                "with the session origin; owner: droplive generates a secret "
                "instead and the application receives that in place of its URL"
            )

    for path in sorted(recipe_file.parent.iterdir()):
        if not path.is_file() or path.name == "droplive.yaml":
            continue
        try:
            text = path.read_text(errors="replace")
        except OSError:
            continue

        annotations = list(BOOTSTRAP_ANNOTATION.finditer(text))
        unparsed = len(ANNOTATION_LINE.findall(text)) - len(annotations)
        if unparsed > 0:
            errors.append(
                f"{path.name}: {unparsed} `# droplive:` line(s) do not match the "
                "annotation grammar, so nothing reads them"
            )

        # An annotation is read from the copied entrypoint script and nowhere
        # else, so one in a Dockerfile or a Compose file does nothing at all.
        if annotations and (
            path.name == "Dockerfile"
            or path.name.startswith("Dockerfile.")
            or path.name in ("docker-compose.yaml", "docker-compose.yml")
        ):
            errors.append(
                f"{path.name}: a `# droplive:` annotation is only read in the "
                "copied entrypoint script, so this one does nothing"
            )
            continue

        required = set(REQUIRED_VALUE.findall(text))
        capabilities = 0
        for match in annotations:
            name = match.group("name")
            if name not in required:
                errors.append(
                    f'{path.name}: {name} is annotated but never required; add '
                    f': "${{{name}:?...}}" in the same script'
                )
            if not CREDENTIAL_WORD.search(name):
                errors.append(
                    f"{path.name}: {name} needs PASSWORD, PASS, SECRET or TOKEN "
                    "as a whole word to be read as a bootstrap credential"
                )
            capability = match.group("capability")
            if capability:
                capabilities += 1
                if capability != f"{match.group('purpose')}-login":
                    errors.append(
                        f"{path.name}: {name} has capability={capability} but "
                        f"purpose={match.group('purpose')}-bootstrap; they must agree"
                    )
        if capabilities > 1:
            errors.append(
                f"{path.name}: {capabilities} annotations carry capability=; a "
                "second one silently removes the sign-in card"
            )

        for match in EXACT_LENGTH_TEST.finditer(text):
            errors.append(
                f"{path.name}: exact-length check `{match.group(0).strip()[:72]}` "
                "rejects a longer, usable value; compare with -lt instead"
            )

    return errors


def path_errors(recipe_file: Path, recipe: dict[str, Any]) -> list[str]:
    relative = recipe_file.relative_to(RECIPES)
    product = recipe.get("product")
    if recipe.get("kind") == "mcp" and product:
        if len(relative.parts) != 5 or relative.parts[3] != product:
            return [
                "MCP product recipe path must be "
                "recipes/mcp/<github-owner>/<github-repository>/<product>/droplive.yaml"
            ]
    elif len(relative.parts) != 4:
        return ["recipe path must be recipes/<kind>/<github-owner>/<github-repository>/droplive.yaml"]
    elif product:
        return ["product is only valid for a nested MCP product recipe"]
    folder_kind = relative.parts[0]
    if recipe.get("kind") != folder_kind:
        return [f"kind {recipe.get('kind')} does not match folder {folder_kind}"]
    if recipe_file.parent.is_symlink():
        return ["recipe folders cannot be symbolic links"]
    errors: list[str] = []
    seed_script = recipe_file.parent / "seed.sh"
    if seed_script.exists():
        if seed_script.is_symlink() or not seed_script.is_file():
            errors.append("seed.sh must be a regular file")
        elif not seed_script.read_text(errors="replace").startswith("#!"):
            errors.append("seed.sh must start with a shebang")
    seed = recipe.get("seed")
    if seed and not (recipe_file.parent / seed["archive"]).is_file():
        errors.append(f"seed archive does not exist: {seed['archive']}")
    return errors


def repository_errors(recipe_file: Path, recipe: dict[str, Any]) -> list[str]:
    """The repository URL must name the same project the folder does.

    The folder is the on-disk address and the URL is the identity of record. When
    they disagree, one of them is wrong and nothing downstream can tell which --
    `Recipes.Publish` builds the project from the path, and the forge refresher
    reads the URL.
    """

    url = recipe.get("repository")
    if not isinstance(url, str):
        return []

    # recipes/<kind>/<owner>/<repo>/... -- an MCP recipe adds a product below.
    parts = recipe_file.relative_to(RECIPES).parts
    if len(parts) < 3:
        return []
    owner, repo = parts[1], parts[2]

    tail = url.rstrip("/").split("/")[-2:]
    if len(tail) != 2 or [part.lower() for part in tail] != [owner.lower(), repo.lower()]:
        return [
            f"repository {url} does not name {owner}/{repo}, "
            "which is the folder this recipe lives in"
        ]
    return []


def tagline_errors(recipe_file: Path, recipe: dict[str, Any]) -> list[str]:
    """A tagline answers "what kind of thing is this", in a grid cell.

    Length and shape are the schema's job. What it cannot check is the two ways a
    tagline stops doing its work: repeating the name already printed above it, and
    being written as a sentence.
    """

    tagline = recipe.get("tagline")
    if not isinstance(tagline, str):
        return []

    errors: list[str] = []
    parts = recipe_file.relative_to(RECIPES).parts
    names = {parts[2].lower()} if len(parts) >= 3 else set()
    if len(parts) >= 5:
        names.add(parts[3].lower())

    squashed = re.sub(r"[^a-z0-9]", "", tagline.lower())
    for name in names:
        flat = re.sub(r"[^a-z0-9]", "", name)
        if flat and flat in squashed:
            errors.append(
                f"tagline {tagline!r} repeats the project name, which is already "
                "shown beside it"
            )
            break

    # Sentence case: one leading capital, and no capital elsewhere unless the word
    # is capitalised in its own right (S3, GitHub, Markdown).
    if tagline[:1].islower():
        errors.append(f"tagline {tagline!r} must start with a capital")

    return errors


def main() -> int:
    schema = json.loads(SCHEMA.read_text())
    Draft202012Validator.check_schema(schema)
    validator = Draft202012Validator(schema)
    capability_document = yaml.safe_load(CAPABILITIES.read_text())
    capabilities = capability_document["capabilities"]
    companion_document = yaml.safe_load(COMPANIONS.read_text())
    companions = companion_document["companions"]
    recipe_files = sorted(RECIPES.glob("**/droplive.yaml"))
    errors: list[str] = []

    for recipe_file in recipe_files:
        relative = recipe_file.relative_to(ROOT)
        try:
            recipe = yaml.safe_load(recipe_file.read_text())
        except yaml.YAMLError as exc:
            errors.append(f"{relative}: YAML parse failed: {exc}")
            continue
        if not isinstance(recipe, dict):
            errors.append(f"{relative}: recipe must be a YAML object")
            continue

        schema_errors = sorted(validator.iter_errors(recipe), key=lambda item: list(item.path))
        for error in schema_errors:
            errors.append(f"{relative}:{location(list(error.path))}: {error.message}")
        if schema_errors:
            continue

        checks = (
            path_errors(recipe_file, recipe)
            + repository_errors(recipe_file, recipe)
            + tagline_errors(recipe_file, recipe)
            + entrypoint_errors(recipe_file, recipe)
            + build_errors(recipe_file, recipe)
            + managed_data_errors(recipe_file, recipe)
            + capability_errors(recipe, capabilities)
            + world_errors(recipe, capabilities)
            + companion_errors(recipe, companions)
            + mcp_errors(recipe, recipe_file)
        )
        errors.extend(f"{relative}: {message}" for message in checks)

    if not recipe_files:
        errors.append("no recipes found")
    if errors:
        print("\n".join(errors), file=sys.stderr)
        print(f"recipes={len(recipe_files)} errors={len(errors)}", file=sys.stderr)
        return 1
    print(f"recipes={len(recipe_files)} errors=0")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
