# WWDCTranslate
The script turns the page WWDC `.html` to `.srt` format subtitles.

## How to use
1. Open the page with the video you are interested in.
```
https://developer.apple.com/videos/play/wwdc2022/10068/
```
2. Testing was carried out for two languages: `EN` and `RU`.
    * `EN`
        1. Right-click and select `Save Page as...` in the pop-up menu.
        2. In the Finder menu, select `Save the entire page` and click `Save`.
        3. In the command line, go to the path of directory where the script was saved and enter the following command:
            ```
            ./script.swift "/{path}/{filename}.html" "{pathToDirectory}"
            ```
        4. Download the video from the page from point `{1}`.
        5. Open a video in a player that supports subtitles and transfer the generated document `.sdt`.
    * `RU`
    To translate into Russian, I advise to use Yandex browser and its built-in translator. Next steps are suggested for this browser.
        1. Go to the `Transcript` tab on the video page.
        2. In the navigation bar select `Translate page to Russian` and start slowly flipping through `Transcript`.
        3. As soon as the entire transcription is translated, do all the steps from the `EN` point.