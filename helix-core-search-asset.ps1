# Function starts
function Get-ParamsFiles {
    param (
      $argsQuoted
    )
    $fileStr = ""
    $skipNext = $false
    $words = $argsQuoted.Split(',')

    foreach ($word in $words) {
        if ( -Not $skipNext ) {
            $file, $skip = Get-File( $word )
            if ( $file ) {
                # This must be one of the actual path we want. Append to fileStr
                $fileStr = ( $fileStr , $file ) -join ","
            }
            $skipNext = $skip
        }
        else {
            $skipNext = $false
        }
    }
    # Remove first comma
    $fileStr = $fileStr -replace "^,", ""
    return $fileStr
}
# Function ends

# Function starts
function Get-File {
    param (
      $word
    )
    $word = $word.Trim()

    if ( $word  -eq '-n' -Or $word -eq '-v' ) {
        return $null, $true
    } elseif ( $word  -like '-*' ) {
        # Ignore option
        return $null, $false
    } else {
        # This must be one of the actual path we want. Append to fileStr
        return $word, $false
    }
}
# Function ends

# Script main starts
$token = $args[0]
$argsQuoted = $args[1]
$client = $args[2]
$clientcwd = $args[3]

$decodedString = [System.Web.HttpUtility]::UrlDecode($argsQuoted)
Write-Host "Decoded argsQuoted: " $argsQuoted

# Separate parameters and files within argsQuoted
$fileStr = Get-ParamsFiles $argsQuoted
Write-Host "Files: " $fileStr

Write-Host "Going to index attributes in ElasticSearch..."

$Header = @{
    "X-Auth-Token" = "$token"
}
$BodyJson = @{
    "clientcwd" = "$clientcwd"
    "client" = "$client"
    "argsQuoted" = "$fileStr"
} | ConvertTo-Json
$Parameters = @{
    Method		= "PATCH"
    Uri			= "http://p4search.mydomain.com:1601/api/v1.2/index/asset"
    Headers		= $Header
    ContentType	= "application/json"
    Body		= $BodyJson
}
    Invoke-RestMethod @Parameters
}

# Test cases
#"-nTAG1,-f,Dockerfile,//depot/...,src/main/java/file/FileEnd-Point.java"
#"-n,TAG1,-f,Dockerfile,//depot/...,src/main/java/file/FileEnd-Point.java"
# "-n,TAG1,-v,VAL1,-f,Dockerfile,//depot/...,src/main/java/file/FileEndPoint.java"
# "-nTAG1,-vVAL1,-f,Dockerfile,//depot/...,src/main/java/file/FileEndPoint.java"
  
# Script main ends