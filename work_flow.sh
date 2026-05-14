git checkout -b feature/ci-observe

# 把 workflow snippets 複製到 .github/workflows/
cp snippets/01_hello.yaml .github/workflows/
cp snippets/02_run-test.yaml .github/workflows/
cp snippets/ci.yaml .github/workflows/
cp snippets/cd.yaml .github/workflows/

# commit and push to GitHub
git add .github/workflows
git commit -m "ci: add github actions workflows"
git push origin feature/ci-observe

