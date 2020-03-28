# zpl-viewer
A Desktop ZPL Zebra Programming Language Viewer / Printer Emulator

ZPL-Viewer emulates a Jet-Direct port on your desktop, and renders incoming printer data directly on the screen.
As backend, it uses labelary.com´s online REST-Api, which is currently free (fair use).
Dont forget to open your desktop firewall (TCP port 9100).

When installing a Zebra printer on Windows, use "127.0.0.1" as host, and TCP-port 9100. Of course also works with "Zebra-Designer".

For your convenience, please find pre-compiles binaries for Windows in each of the releases. Thanks to the Lazarus compiler environment, you do not need any runtime whatsoever - just run the exe-file.
