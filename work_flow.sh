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

# modify ci.yaml
# add your steps here, e.g. lint, test, build etc.
- name: Type check
    run: npm run typecheck

- name: Run tests
    run: npm test

- name: Build app
    run: npm run build

git add .
git commit -m "ci: add github actions: type check, test and build steps"
git push origin feature/ci-observe