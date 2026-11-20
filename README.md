# eevion-skills

## 1. 创建仓库

创建一个 Git 仓库并克隆到本地。把共享 skill 放在仓库根目录，每个 skill 一个文件夹，例如 `eevion-web-dev-spec/SKILL.md`。

## 2. 接入 Codex

在仓库根目录，给需要的 skill 建一个用户级目录链接，本机所有项目就能共用它。下面以前端规范为例，换掉名字即可接入其他 skill。

**Windows（PowerShell）**

```powershell
$skill = 'eevion-web-dev-spec'
$dir = "$env:USERPROFILE/.agents/skills"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
New-Item -ItemType Junction -Path "$dir/$skill" -Target (Resolve-Path $skill).Path
```

**macOS / Linux**

```sh
skill=eevion-web-dev-spec
mkdir -p ~/.agents/skills
ln -s "$PWD/$skill" ~/.agents/skills/
```

## 3. 日常使用

项目可以在 `AGENTS.md` 里按名称引用 skill。修改规范时只改共享仓库，本机通过链接读取更新。推送后，其他电脑在共享仓库运行 `git pull --ff-only` 即可同步。每台电脑首次使用或新增 skill 时，做一次第 2 步。
