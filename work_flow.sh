git checkout -b feature/ci-observe

# 把 workflow snippets 複製到 .github/workflows/
cp snippets/01_hello.yaml .github/workflows/
cp snippets/02_run-test.yaml .github/workflows/
cp snippets/ci.yaml .github/workflows/
cp snippets/cd.yaml .github/workflows/

# commit and push to GitHub
git add .
git commit -m "ci: add github actions workflows"
git push origin feature/ci-observe

# install act
brew install act
docker compose up -d --build


git add .
git commit -m "ci: add github actions: type check, test and build steps"
git push origin feature/ci-observe

# npm test error
# test/app.test.ts
git add .
git commit -m "ci: add github actions: npm test error"
git push origin feature/ci-observe

# step 1. check code format
npm run format:check
> my-app@1.0.0 format:check
> prettier --check .

Checking formatting...
[warn] .github/workflows/01_hello.yaml
[warn] .github/workflows/02_run-test.yaml
[warn] .github/workflows/ci_111550006.yaml
[warn] .vscode/settings.json
[warn] docker-compose.yml
[warn] snippets/01_hello.yaml
[warn] snippets/02_run-test.yaml
[warn] Code style issues found in 7 files. Run Prettier to fix.

# step 2. fix code format
# 縮排問題，使用 prettier 自動修正
npx prettier --write .github/workflows/01_hello.yaml
npx prettier --write .github/workflows/02_run-test.yaml
npx prettier --write .github/workflows/ci_111550006.yaml # "" -> ''
npx prettier --write .vscode/settings.json
npx prettier --write docker-compose.yml
npx prettier --write snippets/01_hello.yaml
npx prettier --write snippets/02_run-test.yaml

git add .
git commit -m "ci: add github actions: fix prettier format issues"
git push origin feature/ci-observe