![Support](https://img.shields.io/badge/Support-None-red.svg)

# Helix Core Search Asset

This project demonstrates how to keep the Helix Core Search service up-to-date with the latest submitted changes.  
It uses an example Helix Core Lua Extension and is intended to be customised to suit a specific Helix installation.


## Overview

The Lua Extension will need to be installed on the Helix Core Server and is invoked by post-attribute event.
This document describes the necessary steps to customize and install the extension to run on any Helix Core Server.

Extensions are not currently supported on Helix Core on Windows. As an alternative to extensions, you can configure a trigger to index changes.

Here's an example- [Asset trigger on windows](#asset-trigger-on-windows)

## Requirements

The extension requires a Helix Core Server version that supports extensions. This is 2019.2 or later for Linux systems.
You will also need the following correctly setup and working:

#### Helix Core Search service (p4search)
You'll need a 'p4search' service running and accessible from the Helix Core Server where this extension will be installed.

#### A Helix User for creating extension
Helix Server `super` access is required to create Server Side Extension.

#### Credentials to access p4search
You will need a valid `X-Auth-Token` defined in the 'p4search' configuration.

## Documentation

Please refer to [Helix Core Search Developer Guide](https://www.perforce.com/manuals/p4search/Content/P4Search/keep-index-up-to-date.html#Use_a_Perforce_Lua_extension) to use our officially signed extension.

## Support

This project is an example and provided as-is.  
Perforce offers no support for issues (either via GitHub nor via Perforce's standard support process).  All pull requests will be ignored.

## Build/Usage

(1) Ensure that the Helix Core Server has an extension depot. If not, create one using

    p4 depot -t extension extensions

(2) Create skeleton of a Helix Server Extension with name `helix-core-search-asset`. You need to be in the parent directory of `helix-core-search-asset`.

    git clone https://github.com/perforce/helix-core-search-asset.git
    
    p4 extension --package helix-core-search-asset

This will create an extension skeleton named `helix-core-search-asset.p4-extension`.

(3) Install the Helix Server Extension.

    p4 extension -y --allow-unsigned --install helix-core-search-asset.p4-extension

You can skip the `--allow-unsigned` option if your server allows unsigned extensions.

(4) Configure the extension's global settings and change the `ExtP4USER` to match your extension user (without altering spaces/tabs).

(5) Configure the extension's instance settings.

    p4 extension --configure Perforce::helix-core-search-asset --name Perforce

(6) For more information on Helix Server Extensions, please refer to the [Helix Core Extensions Developer Guide](https://www.perforce.com/manuals/extensions/Content/Extensions/Home-extensions.html)

Here are some useful commands to work with extensions.

(1) List the extensions on a Helix Core Server.

    p4 extension --list --type=extensions

(2) List the extension's configurations.

    p4 extension --list --type=configs

(3) Delete the extension's directory and extension from Helix Core Server.

    rm -f helix-core-search-asset.p4-extension    
    p4 extension -y --delete Perforce::helix-core-search-asset


## Asset trigger on Windows

(1) Create a powershell script. For your convenience, here's an [example script](helix-core-search-asset.ps1).
Make sure you change the Uri from `http://p4search.mydomain.com:1601` as per your configuration.

(2) Save this file as helix-core-search-asset.ps1. Add this file to Helix Core preferably at //depot/triggers/....

(3) Edit the triggers table by running `p4 triggers` and add the following to the triggers table. Make sure you change the X-Auth-Token as per your configuration.

    helix-core-search-asset command pre-user-attribute "powershell.exe %//depot/triggers/helix-core-search-asset.ps1% 00000000-0000-0000-0000-000000000000 %argsQuoted% %client% %clientcwd%"

Done! Now, Helix Core Search will index attributes in ElasticSearch whenever a file is tagged.
    