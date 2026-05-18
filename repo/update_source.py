import json
import logging
import os
import re
import requests
from datetime import datetime
from typing import Dict, List, Optional, Any, TypedDict, Tuple

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)

MAX_RECENT_ENTRIES = 5


class ReleaseAsset(TypedDict):
    browser_download_url: str
    name: str
    size: int


class GitHubRelease(TypedDict):
    tag_name: str
    published_at: str
    body: str
    assets: List[ReleaseAsset]


class VersionEntry(TypedDict):
    version: str
    date: str
    localizedDescription: str
    downloadURL: Optional[str]
    size: Optional[int]


class AppInfo(TypedDict):
    versions: List[VersionEntry]
    version: str
    versionDate: str
    versionDescription: str
    downloadURL: Optional[str]
    size: Optional[int]


class NewsEntry(TypedDict):
    appID: str
    title: str
    identifier: str
    caption: str
    date: str
    tintColor: str
    imageURL: str
    notify: bool
    url: str


class AppData(TypedDict):
    apps: List[Dict[str, Any]]
    news: List[NewsEntry]


class AppConfig(TypedDict):
    repo_url: str
    json_file: str
    app_id: str
    app_name: str
    caption: str
    tint_colour: str
    image_url: str


def load_config(config_path: str) -> AppConfig:
    """
    Load repo configuration values.

    Args:
        config_path: File path for configuration details

    Returns:
        AppConfig: Dictionary with config values

    Raises:
        FileNotFoundError: If config file doesn't exist
        ValueError: If required fields are missing
    """
    try:
        with open(config_path, "r") as config_file:
            config_data = json.load(config_file)

        required_fields = [
            "repo_url",
            "json_file",
            "app_id",
            "app_name",
            "caption",
            "tint_colour",
            "image_url",
        ]
        missing_fields = [
            field for field in required_fields if field not in config_data
        ]

        if missing_fields:
            raise ValueError(
                f"Missing required configuration fields: {', '.join(missing_fields)}"
            )

        return {
            "repo_url": config_data["repo_url"],
            "json_file": config_data["json_file"],
            "app_id": config_data["app_id"],
            "app_name": config_data["app_name"],
            "caption": config_data["caption"],
            "tint_colour": config_data["tint_colour"],
            "image_url": config_data["image_url"],
        }

    except FileNotFoundError:
        logging.exception(f"Configuration file not found at {config_path}")
        raise
    except json.JSONDecodeError as e:
        logging.exception(f"Invalid JSON in configuration file: {e}")
        raise
    except ValueError as e:
        logging.exception(str(e))
        raise


def fetch_all_releases(repo_url: str) -> List[GitHubRelease]:
    """
    Fetch all GitHub releases for the repository, sorted by published date (oldest first).

    Args:
        repo_url: The GitHub repo url (user/repo)

    Returns:
        List[GitHubRelease]: List of all releases sorted by publication date

    Raises:
        requests.RequestException: If the API request fails
    """
    api_url: str = f"https://api.github.com/repos/{repo_url}/releases"
    headers: Dict[str, str] = {"Accept": "application/vnd.github+json"}
    github_token = os.getenv("GITHUB_TOKEN")
    if github_token:
        headers["Authorization"] = f"Bearer {github_token}"

    releases: List[GitHubRelease] = []
    page = 1

    while True:
        try:
            response = requests.get(
                api_url,
                headers=headers,
                params={"per_page": 100, "page": page},
                timeout=30,
            )
            response.raise_for_status()
        except requests.RequestException as e:
            logging.exception(f"Failed to fetch releases from {api_url}: {e}")
            raise

        page_releases: List[GitHubRelease] = response.json()
        releases.extend(page_releases)

        if len(page_releases) < 100:
            break

        page += 1

    sorted_releases = sorted(releases, key=lambda x: x["published_at"], reverse=False)

    logging.info(f"Fetched {len(sorted_releases)} releases from {repo_url}")
    return sorted_releases


def find_latest_installable_release(releases: List[GitHubRelease]) -> GitHubRelease:
    """
    Find the newest release with an IPA asset.

    Args:
        releases: List of GitHub releases

    Returns:
        GitHubRelease: The latest release that can be installed

    Raises:
        ValueError: If no release includes an IPA asset
    """
    sorted_releases = sorted(releases, key=lambda x: x["published_at"], reverse=True)

    for release in sorted_releases:
        if any(asset["name"].endswith(".ipa") for asset in release["assets"]):
            logging.info(f"Latest installable release: {release['tag_name']}")
            return release

    raise ValueError("No installable releases with IPA assets found")


def format_description(description: str) -> str:
    """
    Format release description by removing HTML tags and replacing certain characters.

    Args:
        description: The raw description text

    Returns:
        str: Cleaned description text
    """
    # Remove HTML tags
    formatted = re.sub(r"<[^>]+>", "", description)
    # Remove Markdown header tags
    formatted = re.sub(r"#{1,6}\s?", "", formatted)
    # Replace Markdown bullet markers and formatting characters.
    formatted = re.sub(r"(?m)^(\s*)[-*]\s+", r"\1• ", formatted)
    formatted = formatted.replace("**", "").replace("`", '"')

    return formatted


def find_download_url_and_size(
    release: GitHubRelease,
) -> Tuple[Optional[str], Optional[int]]:
    """
    Find the download URL and size for a release's IPA file.

    Args:
        release: The GitHub release

    Returns:
        tuple: (download_url, size) or (None, None) if not found
    """
    for asset in release["assets"]:
        if asset["name"].endswith(".ipa"):
            return asset["browser_download_url"], asset["size"]

    logging.warning(f"No IPA file found for release {release['tag_name']}")
    return None, None


def normalize_version(version: str) -> str:
    """
    Strip the version tag (e.g., -hotfix) from a version string.

    Args:
        version: Version string (e.g., v0.5.2-hotfix, 0.5.2-beta)

    Returns:
        Normalized version string without the tag (e.g., 0.5.2)
    """
    version = version.lstrip("v")

    match = re.search(r"(\d+\.\d+\.\d+)", version)
    if match:
        return match.group(1)
    return version


def process_versions(versions_data: List[VersionEntry]) -> List[VersionEntry]:
    """
    Process the versions list to remove duplicate versions, keeping the newest version.

    Args:
        versions_data: List of version dictionaries

    Returns:
        List[VersionEntry]: Processed list with only the newest versions
    """
    version_dict: Dict[str, VersionEntry] = {}

    for version in versions_data:
        current_date = datetime.fromisoformat(version["date"].replace("Z", "+00:00"))
        version_key = version["version"]

        if version_key in version_dict:
            # Compare dates and keep the newer version
            existing_date = datetime.fromisoformat(
                version_dict[version_key]["date"].replace("Z", "+00:00")
            )

            if current_date > existing_date:
                version_dict[version_key] = version
        else:
            version_dict[version_key] = version

    result = list(version_dict.values())
    logging.info(
        f"Processed {len(versions_data)} versions, kept {len(result)} unique versions"
    )

    return result


def purge_old_entries(data: AppData, max_entries: int = MAX_RECENT_ENTRIES) -> None:
    """
    Keep only the newest version and news entries in the source data.

    Args:
        data: The source JSON data
        max_entries: Number of recent entries to keep
    """
    for app in data.get("apps", []):
        versions = app.get("versions")
        if not isinstance(versions, list):
            continue

        sorted_versions = sorted(
            versions,
            key=lambda version: version.get("date", ""),
            reverse=True,
        )
        app["versions"] = sorted_versions[:max_entries]
        logging.info(
            f"Purged versions from {len(sorted_versions)} to {len(app['versions'])} entries"
        )

    if "news" not in data or not isinstance(data["news"], list):
        return

    sorted_news = sorted(
        data["news"],
        key=lambda news_entry: news_entry.get("date", ""),
        reverse=True,
    )
    data["news"] = sorted_news[:max_entries]
    logging.info(f"Purged news from {len(sorted_news)} to {len(data['news'])} entries")


def update_json_file(
    config: AppConfig,
    json_file: str,
    fetched_data_all: List[GitHubRelease],
    fetched_data_latest_installable: GitHubRelease,
) -> None:
    """
    Update the source file with the fetched GitHub releases.

    Args:
        config: Configuration object with the repo/app details
        json_file: Path to the JSON file
        fetched_data_all: List of all GitHub releases
        fetched_data_latest_installable: The latest GitHub release with an IPA asset

    Raises:
        ValueError: If JSON structure is invalid or version format is incorrect
    """
    try:
        with open(json_file, "r") as file:
            data: AppData = json.load(file)
    except FileNotFoundError:
        logging.exception(f"JSON file not found at {json_file}")
        raise
    except json.JSONDecodeError as e:
        logging.exception(f"Invalid JSON in {json_file}: {e}")
        raise

    if "apps" not in data or not data["apps"]:
        raise ValueError("Invalid JSON structure: 'apps' array is missing or empty")

    app = data["apps"][0]

    releases = []

    # Process all releases
    for release in fetched_data_all:
        full_version = release["tag_name"].lstrip("v")
        version_match = re.search(r"(\d+\.\d+\.\d+)", full_version)

        if not version_match:
            logging.warning(
                f"Skipping release with invalid version format: {release['tag_name']}"
            )
            continue

        version_date = release["published_at"]

        # Get base version without tags
        base_version = normalize_version(full_version)

        # Clean up description
        description = format_description(release["body"])

        # Find download URL and size
        download_url, size = find_download_url_and_size(release)

        # Skip release entries without a download URL
        if not download_url:
            logging.warning(
                f"Skipping release {release['tag_name']} - no IPA file found"
            )
            continue

        # Create version entry
        version_entry: VersionEntry = {
            "version": base_version,
            "date": version_date,
            "localizedDescription": description,
            "downloadURL": download_url,
            "size": size,
        }

        releases.append(version_entry)

    # Process and deduplicate versions
    deduplicated_versions = process_versions(releases)

    # Sort by date (newest first) and update app versions
    app["versions"] = sorted(
        deduplicated_versions, key=lambda x: x.get("date", ""), reverse=True
    )

    # Update app info with latest installable release.
    latest_version = fetched_data_latest_installable["tag_name"].lstrip("v")
    tag = fetched_data_latest_installable["tag_name"]
    version_match = re.search(r"(\d+\.\d+\.\d+)", latest_version)

    if not version_match:
        raise ValueError(f"Invalid version format for latest release: {latest_version}")

    app["version"] = normalize_version(latest_version)
    app["versionDate"] = fetched_data_latest_installable["published_at"]
    app["versionDescription"] = format_description(
        fetched_data_latest_installable["body"]
    )

    # Find latest download URL and size
    download_url, size = find_download_url_and_size(fetched_data_latest_installable)
    app["downloadURL"] = download_url
    app["size"] = size

    # Update news entries
    if "news" not in data:
        data["news"] = []

    # Add news entry for the latest version if it doesn't exist
    news_identifier = f"release-{latest_version}"
    if not any(item["identifier"] == news_identifier for item in data["news"]):
        try:
            formatted_date = datetime.strptime(
                fetched_data_latest_installable["published_at"], "%Y-%m-%dT%H:%M:%SZ"
            ).strftime("%d %b")
        except ValueError as e:
            logging.exception(f"Error parsing date: {e}")
            formatted_date = "Unknown"

        news_entry: NewsEntry = {
            "appID": config["app_id"],
            "title": f"{latest_version} - {formatted_date}",
            "identifier": news_identifier,
            "caption": config["caption"],
            "date": fetched_data_latest_installable["published_at"],
            "tintColor": config["tint_colour"],
            "imageURL": config["image_url"],
            "notify": True,
            "url": f"https://github.com/{config['repo_url']}/releases/tag/{tag}",
        }
        data["news"].append(news_entry)
        logging.info(f"Added news entry for version {latest_version}")

    purge_old_entries(data)

    # Write updated data back to file
    try:
        with open(json_file, "w") as file:
            json.dump(data, file, indent=2)
        logging.info(f"Successfully updated {json_file}")
    except IOError as e:
        logging.exception(f"Failed to write to {json_file}: {e}")
        raise


def main() -> None:
    """
    Entrypoint for GitHub workflow action.
    """
    try:
        logging.info("Starting release update process")

        config = load_config("repo/config.json")
        fetched_data_all = fetch_all_releases(config["repo_url"])
        fetched_data_latest_installable = find_latest_installable_release(
            fetched_data_all
        )
        update_json_file(
            config,
            config["json_file"],
            fetched_data_all,
            fetched_data_latest_installable,
        )

        logging.info(f"Successfully updated {config['json_file']} with latest releases")

    except Exception as e:
        logging.exception(f"Error updating releases: {e}")
        raise


if __name__ == "__main__":
    main()
