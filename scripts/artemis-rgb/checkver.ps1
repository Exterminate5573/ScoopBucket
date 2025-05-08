$ReleasesParams = @{
  Uri     = 'https://updating.artemis-rgb.com/graphql'
  Method  = 'POST'
  Headers = @{
    'Content-Type' = 'application/json'
    'User-Agent'   = 'insomnia/11.0.2'
  }
  Body    = @{
    query         = 'query GetReleases($branch: String!, $platform: Platform!) {
        publishedReleases(
            order: {createdAt: DESC}
            first: 1
            where: {
                and: [
                    { branch: { eq: $branch } }
                    { artifacts: { some: { platform: { eq: $platform } } } }
                ]
            }
        ) {
            nodes {
                id
                version
            }
        }
    }'
    operationName = 'GetReleases'
    variables     = @{
      branch   = 'master'
      platform = 'WINDOWS'
    }
  } | ConvertTo-Json -Depth 5
}

$response = Invoke-WebRequest @ReleasesParams
$encoding = [System.Text.Encoding]::GetEncoding("utf-8")
$content = $encoding.GetString($response.Content)

# Parse the JSON response
$json = $content | ConvertFrom-Json

# Extract the version
$ver = $json.data.publishedReleases.nodes[0].version

$id = $json.data.publishedReleases.nodes[0].id

$ArtifactParams = @{
  Uri     = 'https://updating.artemis-rgb.com/graphql'
  Method  = 'POST'
  Headers = @{
    'Content-Type' = 'application/json'
    'User-Agent'   = 'insomnia/11.0.2'
  }
  Body    = @{
    query         = 'query GetReleaseById($id: UUID!) {
        publishedRelease(id: $id) {
            branch
            commit
            version
            artifacts {
                platform
                artifactId
                fileInfo {
                    md5Hash
                }
            }
        }
    }'
    operationName = 'GetReleaseById'
    variables     = @{
      id = $id
    }
  } | ConvertTo-Json -Depth 5
}

$response = Invoke-WebRequest @ArtifactParams
$encoding = [System.Text.Encoding]::GetEncoding("utf-8")
$content = $encoding.GetString($response.Content)

# Parse the JSON response
$json = $content | ConvertFrom-Json

# Iterate through the artifacts and find the one for Windows
$artifacts = $json.data.publishedRelease.artifacts
$windowsArtifact = $artifacts | Where-Object { $_.platform -eq 'WINDOWS' }
$artifactId = $windowsArtifact.artifactId
$md5Hash = $windowsArtifact.fileInfo.md5Hash

"version: $ver artifactId: $artifactId md5Hash: $md5Hash"
