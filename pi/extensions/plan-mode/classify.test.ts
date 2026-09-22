import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { isBlockedBashCommand } from "./classify.ts";

/**
 * Table test over the regression corpus built up across review rounds:
 * each case pins a real bypass or false-positive found (and fixed) at
 * some point, so a future regex tweak that reintroduces one fails loudly
 * here instead of waiting for the next code review round.
 */

const allowed: string[] = [
  "ls -la",
  "cat package.json",
  "pwd",
  "git status",
  "git log",
  "git diff",
  // \b on the git subcommand alternation: must not match a "config"/"init" prefix.
  "git configx",
  "git initialize",
  "npm run build",
  "bun run build",
  "cargo build",
  "go build ./...",
  'grep -rn "mv" .',
  "rg '\\brm\\b' src/",
  "ls src/dd",
  "grep npx README.md",
  // Throwaway redirects (fd dups, /dev/null) never make a real write.
  "rg foo . 2>/dev/null",
  "grep -r TODO . 2>/dev/null | wc -l",
  "ls -la 2>&1 | less",
  "sed -n '1,5p' file.txt",
  "perl -e 'print 1'",
  // curl defaults to stdout, not a file write.
  "curl https://example.com",
  "find . -name '*.ts'",
  // "i" alias must not match the start of "info".
  "npm info left-pad",
  // Removed from WRITE_COMMAND_HEADS: low real-world relevance in exploration.
  "install -m755 src /usr/bin/dst",
  "shred secret.txt",
  "mkfifo mypipe",
  // tar/unzip/patch/rsync: flag-gated read-only forms.
  "tar -tzvf archive.tar",
  "tar -df archive.tar new/",
  "unzip -l archive.zip",
  "unzip -p archive.zip file.txt",
  "patch --dry-run < diff.patch",
  "rsync -an src/ dest/",
  "rsync --dry-run -a src/ dest/",
  // timeout/env/nice/nohup/stdbuf/xargs are peeled, but bash -c's quoted
  // script content isn't parsed anywhere in this classifier — known,
  // accepted gap (non-adversarial, single-user threat model).
  "bash -c 'rm -rf /'",
];

const blocked: string[] = [
  "rm -rf /",
  "rm -rf / 2>/dev/null",
  "rm -rf / 2>/dev/null | cat",
  "sudo rm -rf /",
  "git commit -m x",
  "git commit -m x 2>/dev/null",
  "npm install",
  "npm install 2>/dev/null",
  "bun install",
  "bun add left-pad",
  "git clean -fd",
  "git rm -rf .",
  "git restore .",
  "git switch main",
  "git checkout main",
  "git apply patch.diff",
  "git worktree add ../x",
  "git config user.name x",
  "git submodule add https://example.com/x.git",
  "git remote add origin git@example.com:x.git",
  // Tool-level flags before the subcommand must not hide it.
  "git -C . commit -m x",
  "npm --prefix . install lodash",
  "echo x &> /tmp/y",
  "echo x >| /tmp/y",
  "pip3 install requests",
  "pipx install black",
  "uv add requests",
  "python -m pip install requests",
  "npx create-react-app foo",
  "npx --yes cowsay hi /tmp/x",
  "pnpm dlx cowsay hi",
  "bunx cowsay hi",
  "cargo add serde",
  "go get example.com/pkg",
  "gem install rails",
  "brew install foo",
  "poetry add requests",
  "composer install",
  // npm/pnpm short aliases (i/un/rm/r/up).
  "npm i left-pad",
  "pnpm rm x",
  "yarn un left-pad",
  "curl -o out.txt https://example.com",
  "curl -O https://example.com/file.zip",
  "curl --output out.txt https://example.com",
  "wget https://example.com/file.zip",
  "tar -xf archive.tar",
  "unzip archive.zip",
  "rsync -a src/ dest/",
  "patch -p1 < diff.patch",
  // find needs an action flag to write/execute; bare find above is read-only.
  "find . -delete",
  "find . -name '*.ts' -delete",
  // Wrapper peeling: the real command survives timeout/env/nohup/xargs.
  "timeout 5 rm -rf /",
  "timeout 30s rm -rf /",
  "env rm -rf x",
  "nohup rm -rf /",
  "nice -n5 rm -rf /",
  "find . -type f | xargs rm -rf",
  "find . -type f | xargs -I{} rm -rf {}",
  "/usr/bin/timeout 5 rm -rf /",
  "ls && rm -rf /",
  "echo $(rm -rf ~/work)",
  "echo `rm -rf ~/work`",
  "ls\nrm -rf src",
  "echo hi > /tmp/x\nrm -rf /",
  "rm -rf /tmp/../etc/passwd",
  "echo x > /tmp/../etc/foo",
  "touch /tmp/../../root/x",
  "/bin/rm -rf x",
  "FOO=1 rm -rf x",
  "mv --target-directory=/etc /tmp/x",
  "sed -i s/a/b/ src/f.ts",
  "sed -i.bak s/a/b/ /tmp/f.txt",
  "perl -pi -e 's/a/b/' file",
  "perl -ni -e 'print' f",
  "sed --in-place s/a/b/ src/f.ts",
  "sudo touch /tmp/x",
  "rm /dev/null",
  // "/dev/nullx" is a real path, not the /dev/null throwaway target.
  "echo pwned > /dev/nullx",
  "mkdir -p /tmp/foo && touch /tmp/foo/bar",
  "rm -rf /tmp/foo > /etc/log",
  "mv a.txt /tmp/b.txt",
  "timeout 5 rm -rf x",
  // No target is safe, /tmp included: plan mode blocks every write
  // command outright, regardless of where it points.
  "echo hi > /tmp/out.txt",
  "printf foo > /tmp/log.txt",
  "mkdir -p /tmp/foo",
  "touch /tmp/scratch.txt",
  "rm -rf /tmp/foo",
  "FOO=1 rm -rf /tmp/x",
  "echo hi 2>&1 > /tmp/out.txt",
  "cp a.txt /tmp/b.txt",
];

describe("isBlockedBashCommand", () => {
  for (const command of allowed) {
    it(`allows: ${command}`, () => {
      assert.equal(isBlockedBashCommand(command), false);
    });
  }
  for (const command of blocked) {
    it(`blocks: ${command}`, () => {
      assert.equal(isBlockedBashCommand(command), true);
    });
  }
});
