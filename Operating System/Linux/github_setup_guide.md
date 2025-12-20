# GitHub Setup (Windows and Linux/WSL)

Everything you need to store a GitHub Personal Access Token (PAT), initialize a repo, push to GitHub, and clean up on either Windows or Linux/WSL.

---

## 1. Prerequisites
- Install Git
	- Windows: `winget install --id Git.Git -e --source winget` (then reopen PowerShell so PATH refreshes)
	- Linux/WSL: use your package manager (e.g., `sudo apt install git`)
- If Git is installed but not found, add `C:/Program Files/Git/cmd` (and `.../bin`) to PATH, then restart PowerShell.
- GitHub account and HTTPS repo URL `https://github.com/<username>/<repo>.git`
- Fine-grained PAT recommended; scope to the target repo with Contents: Read/Write, Metadata: Read-only

---

## 2. Store Your PAT Securely

### Windows
```powershell
git config --global credential.helper manager-core
```
- PAT is stored securely in Windows Credential Manager after first use.
- Optional for scripts: `setx GITHUB_TOKEN "your_pat"`

### Linux / WSL
```bash
git config --global credential.helper store
# or (more secure) libsecret helper
git config --global credential.helper /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret
```
- Optional for scripts: `export GITHUB_TOKEN="your_pat"` (add to `~/.bashrc` or `~/.zshrc` if needed).

Security: never commit or share the PAT; revoke it if exposed (GitHub → Settings → Developer settings → Personal access tokens).

---

## 3. Quick Start (Windows PowerShell)

```powershell
# Create project folder and enter it
mkdir my-project
Set-Location my-project

# Initialize and make first commit
git init
git add .
git commit -m "Initial commit"

# Set default branch to main (optional but recommended)
git branch -M main

# Point to your GitHub repo and push
git remote add origin https://github.com/ufuomaikporo/Kubernetes.git
git push -u origin main
```
- Replace the URL with your repo. `-u` sets upstream so future pushes can use `git push` alone.
- If prompted, username = GitHub username; password = PAT. Credential Manager caches it.

**Rename an existing local branch to main (if you already have commits):**
```powershell
git branch -M main
git push -u origin main
```

---

## 4. Quick Start (Linux / WSL)

```bash
# Create project folder and enter it
mkdir -p ~/projects/my-project
cd ~/projects/my-project

# Initialize and set main as default branch (if needed)
git init
git branch -M main

# Optional: create a starter .gitignore
printf "*.log\n*.tmp\n__pycache__/\n" > .gitignore

# First commit
git add .
git commit -m "Initial commit"

# Point to your GitHub repo and push
git remote add origin https://github.com/<username>/<repo>.git
git push -u origin main
```
- Username = GitHub username; password = PAT when prompted.

---

## 5. Cross-Platform Checklist (bash / zsh / PowerShell)
1) Init repo: `git init` (optionally `git branch -M main`)
2) Stage and commit: `git add .` then `git commit -m "Initial commit"`
3) Add remote: `git remote add origin https://github.com/<username>/<repo>.git`
4) Push: `git push -u origin main`
5) Verify: `git status`, `git remote -v`, `git pull`

---

## 6. Cleanup and Removal

### Disconnect remote (keep history)
```bash
git remote remove origin
```

### Remove Git tracking (keep files)
```bash
rm -rf .git        # Linux / WSL
Remove-Item -Recurse -Force -LiteralPath .git   # Windows PowerShell
```

### Delete the repo on GitHub
GitHub → Settings → Danger Zone → Delete this repository → type the name to confirm.

### Revoke the PAT
GitHub → Settings → Developer settings → Personal access tokens → delete/revoke token.

---

## 7. Best Practices
- Use fine-grained PATs; scope to the repo you need.
- Add `.gitignore` before first commit to avoid noise and secrets.
- Do not initialize the GitHub repo with README/.gitignore if you already committed locally; push first, then add README.
- Avoid committing secrets; rotate PATs if exposed.

