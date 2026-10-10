---
name: recommend-songs
description: Recommend songs from the user's taste, or take an exact song list, then download them in 320kbps. Any language or artist. JioSaavn .m4a with tags and cover; mp3 fallback sites.
disable-model-invocation: true
---

# Recommend and download songs

Script: `scripts/songdl.py` (relative to this skill directory). It needs `python3`, `curl`, `ffmpeg`, and `openssl`. Run `python3 scripts/songdl.py` with no arguments to see the usage.

Work in a folder `~/Music/<name>/.work/`. The default output folder is `~/Music/<name>`. Ask the user for `<name>`, for example their own name or a playlist name.

## 1. Select the mode

Ask with the `question` tool, unless the request already makes the mode clear:

- **List mode**: the user gives songs as a file or as text. Write them to `list.txt`, one per line, as `Title|Artist` or `Title`. Go to step 3.
- **Taste mode**: the user wants recommendations. Go to step 2.

## 2. Taste mode: build the list

Do not invent song titles. Take each title from `songdl.py artist` output.

1. Interview the user with the `question` tool, one round at a time. Give a recommended answer for each question. Ask for:
   - favourite artists and songs,
   - moods,
   - eras,
   - languages and their mix,
   - number of songs,
   - versions to skip.

   Write the answer options from the user's earlier answers. Do not assume a genre, language, or region.

2. For each named artist and each similar artist that you suggest, run `python3 scripts/songdl.py artist "<Artist>" -n 50 > artist-<slug>.tsv`.
3. Pick about 40 representative songs from the artists' top lists. Group them by era or style, and show them in `question` calls with `multiple: true`, so the user can select the songs they like. Also ask which styles the user likes most.
4. Write a short taste profile: main artists, moods, eras, and mix. Get the user's confirmation with the `question` tool before you continue.
5. Use the profile to select songs from the `artist-*.tsv` files until you reach the count. Respect the language mix. Remove duplicates. Write `list.txt` as `Title|Main singer`.
6. If the user does not want to review the full list, show the count per artist and about 15 sample songs.

## 3. Resolve

```bash
python3 scripts/songdl.py resolve list.txt > songs.tsv 2> resolve.err
cut -f1,3 songs.tsv | sort | uniq -c
```

This step makes several requests for each song. For more than 100 songs, run it in the background and poll it.

## 4. Review only the doubtful rows

- Show the `weak` rows as "asked → found (artist, album)". Ask the user to keep or drop them in one `question` call with `multiple: true`.
- Show the `miss` rows. Ask the user to correct the spelling or to drop the song. Run `resolve` again for the corrected lines only, and append the result.
- Delete the dropped rows from `songs.tsv`. Do not show the `ok` rows unless the user asks for them.

## 5. Download in the background

```bash
nohup python3 scripts/songdl.py download songs.tsv ~/Music/<name> > download.log 2>&1 &
```

- Tell the user how to watch progress: `tail -f download.log` and `ls ~/Music/<name> | wc -l`.
- Lines that start with `!!` are failures.
- Rerunning the same command resumes the download. Songs already in `~/Music/<name>/.ids` or with the same file name are skipped. To add songs later, run steps 1–5 again with the same folder.
- Tell the user that `.m4a` (AAC) files play on all common phones and desktop players.

## 6. Check the downloaded files

```bash
python3 scripts/songdl.py check songs.tsv ~/Music/<name> > check.tsv
```

- The output has one row for each bad file: `id`, `file`, `title`, `artists`, `flags`. Flags: `missing`, `corrupt`, `short` (less than 60 s).
- Show the rows in one `question` call with `multiple: true`. Select nothing by default.
- Delete only the selected files. Remove their ids from `~/Music/<name>/.ids`, so a rerun of step 5 can download them again.
- Never delete a file without the user's confirmation.

## Known limits

- JioSaavn credits can be incomplete. A file can have the name of a co-singer or a composer.
- A `weak` match can be a cover or a different song with the same title. Always show the weak rows to the user.
- Mirror and clone sites of the fallback sites have the same songs. Do not add them.
