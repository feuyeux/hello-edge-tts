param(
    [string]$Language = "english",
    [string]$Gender = "female"
)

$configPath = "shared\language_test_config_clean.json"
if (-not (Test-Path $configPath)) {
    Write-Output "en-US-JennyNeural|Hello from TTS!|English (Default)"
    exit
}

try {
    # Read file with UTF-8 encoding
    $content = Get-Content $configPath -Encoding UTF8 -Raw
    $json = $content | ConvertFrom-Json
    
    if ($json.PSObject.Properties.Name -contains $Language) {
        $config = $json.$Language
        
        if ($Gender -eq "male") {
            $voice = $config.male_voice
        } else {
            $voice = $config.female_voice
        }
        
        $text = $config.test_text
        $name = $config.name
        
        Write-Output "$voice|$text|$name"
    } else {
        Write-Output "en-US-JennyNeural|Hello from TTS!|English (Default)"
    }
} catch {
    Write-Error "Error reading config: $_"
    Write-Output "en-US-JennyNeural|Hello from TTS!|English (Default)"
}
