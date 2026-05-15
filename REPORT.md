# 2026 CI/CD Homework Report

學號：111550006

Repository: https://github.com/DennisRapheal/cicd-lab

Branch: `feature/ci-observe`

## 1. CI Pipeline 說明

本次作業在專案中新增 `.github/workflows/ci_111550006.yaml`，讓 GitHub Actions 在每次 `push` 到任意 branch 或建立 `pull_request` 時自動執行 CI pipeline。這個 pipeline 的目標是在程式碼進入主要分支前，先自動檢查型別、格式與測試結果，避免明顯錯誤被合併。

Workflow 主要內容如下：

```yaml
name: CI

on:
  push:
    branches:
      - '**'
  pull_request:

jobs:
  typecheck:
    name: TypeScript typecheck
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - uses: actions/setup-node@v5
        with:
          node-version: '22'
          cache: npm
      - run: npm ci
      - name: Run TypeScript typecheck
        run: npm run typecheck

  prettier:
    name: Prettier check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - uses: actions/setup-node@v5
        with:
          node-version: '22'
          cache: npm
      - run: npm ci
      - name: Run Prettier check
        run: npm run format:check

  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - uses: actions/setup-node@v5
        with:
          node-version: '22'
          cache: npm
      - run: npm ci
      - name: Run tests
        run: |
          mkdir -p reports
          npm test -- --reporter=default --reporter=junit --outputFile.junit=reports/vitest-junit.xml
      - name: Upload test report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-report
          path: reports/
```

我將 pipeline 設計成三個獨立 job：

- `typecheck`：執行 `npm run typecheck`，使用 TypeScript compiler 檢查型別是否正確。
- `prettier`：執行 `npm run format:check`，確認 YAML、JSON、TypeScript 等檔案符合 Prettier 格式。
- `test`：執行 `npm test`，使用 Vitest 測試 Fastify app 的 `/health` 與 `/` endpoint。

三個 job 分開執行的好處是 GitHub Actions 結果頁可以清楚顯示哪一類檢查失敗。例如格式錯誤只會讓 `Prettier check` 失敗，型別錯誤只會讓 `TypeScript typecheck` 失敗，測試邏輯錯誤則會讓 `Test` 失敗。這樣除錯時可以直接從失敗的 job 進入 log，而不用在同一個大型 script 中尋找錯誤來源。

測試 job 另外使用 `actions/upload-artifact@v4` 上傳 `reports/vitest-junit.xml`。即使測試失敗，因為設定了 `if: always()`，仍然會嘗試保留測試報告，方便在 GitHub Actions 結果頁下載與檢查。

## 2. CI 執行結果截圖

成功執行的 workflow 結果如下：

請貼上 GitHub Actions 中 `.github/workflows/ci_111550006.yaml` 成功執行的截圖。

建議截圖內容包含：

- Workflow 名稱：`CI`
- Branch：`feature/ci-observe`
- 三個成功的 job：`TypeScript typecheck`、`Prettier check`、`Test`
- GitHub Actions 結果頁中的綠色通過狀態

圖 1：CI workflow 成功執行結果

![CI success screenshot](./images/ci-success.png)

測試報告 artifact 結果如下：

請貼上 GitHub Actions run 頁面中 Artifacts 區塊的截圖，或測試 job 中 `Upload test report` step 成功的截圖。

圖 2：GitHub Actions artifact 顯示 `test-report`

![Test report artifact screenshot](./images/test-report-artifact.png)

## 3. 失敗案例說明

為了確認 CI pipeline 可以正確攔截錯誤，我有故意製造失敗案例並推送到 `feature/ci-observe` branch。

### 3.1 Prettier 格式錯誤

一開始執行本機格式檢查時，`npm run format:check` 顯示多個檔案不符合 Prettier 規則：

```text
Checking formatting...
[warn] .github/workflows/01_hello.yaml
[warn] .github/workflows/02_run-test.yaml
[warn] .github/workflows/ci_111550006.yaml
[warn] .vscode/settings.json
[warn] docker-compose.yml
[warn] snippets/01_hello.yaml
[warn] snippets/02_run-test.yaml
[warn] Code style issues found in 7 files. Run Prettier to fix.
```

這代表 `Prettier check` job 在 GitHub Actions 上也會失敗，因為它執行的是同一個指令：

```bash
npm run format:check
```

修正策略是使用 Prettier 自動格式化相關檔案，例如：

```bash
npx prettier --write .github/workflows/01_hello.yaml
npx prettier --write .github/workflows/02_run-test.yaml
npx prettier --write .github/workflows/ci_111550006.yaml
npx prettier --write .vscode/settings.json
npx prettier --write docker-compose.yml
npx prettier --write snippets/01_hello.yaml
npx prettier --write snippets/02_run-test.yaml
```

修正後再次執行：

```text
Checking formatting...
All matched files use Prettier code style!
```

### 3.2 測試失敗

測試失敗案例是修改 `test/app.test.ts`，把 `/health` endpoint 的預期結果從：

```ts
expect(response.json()).toEqual({ status: 'ok' });
```

故意改成：

```ts
expect(response.json()).toEqual({ status: 'fail' });
```

實際的 `/health` endpoint 回傳 `{ status: 'ok' }`，因此 Vitest 會判斷測試預期與實際結果不一致，讓 `Test` job 失敗。這個案例可以驗證 pipeline 確實會攔截錯誤的測試預期。

### 3.3 TypeScript 型別錯誤

TypeScript 失敗案例是修改 `src/app.ts` 中的 port 變數型別。錯誤版本如下：

```ts
const configuredPort: number = process.env.PORT;
```

`process.env.PORT` 的型別是 `string | undefined`，不能直接指派給 `number`。本機執行 `npm run typecheck` 會得到：

```text
src/app.ts(4,9): error TS2322: Type 'string | undefined' is not assignable to type 'number'.
  Type 'undefined' is not assignable to type 'number'.
```

因此 GitHub Actions 的 `TypeScript typecheck` job 也會失敗。這個案例證明 CI pipeline 可以在程式尚未執行前，就先透過靜態型別檢查找出潛在錯誤。

修正方式可以改成明確處理環境變數與預設值，例如：

```ts
const configuredPort = Number(process.env.PORT ?? '3000');
```

若目前沒有實際使用這個變數，也可以直接移除，避免產生未使用或錯誤型別的程式碼。

請貼上失敗的 GitHub Actions 結果頁截圖。

圖 3：CI failure screenshot

![CI failure screenshot](./images/ci-failure.png)

## 4. 使用工具與策略

本次作業主要使用以下工具：

- GitHub Actions：實作雲端 CI pipeline，在 push 與 pull request 時自動檢查程式。
- Node.js 22：作為 CI 執行環境，與專案 `package.json` 的 engine 設定相符。
- npm ci：在 CI 中根據 `package-lock.json` 安裝固定版本依賴，確保每次 workflow 使用一致的套件版本。
- TypeScript：透過 `tsc --noEmit` 做靜態型別檢查。
- Prettier：統一程式碼與 YAML/JSON 格式，減少格式差異造成的維護成本。
- Vitest：測試 Fastify app 的 API endpoint 是否回傳預期結果。
- GitHub Actions artifact：保存 JUnit 測試報告，讓測試結果可以在 workflow 結束後下載。
- act：在本機模擬 GitHub Actions push event，減少每次修改都必須推送到 GitHub 才能驗證的等待時間。

整體策略是先在本機用 `npm run format:check`、`npm run typecheck`、`npm test` 做基本檢查，再推送到 GitHub 讓 Actions 執行完整 pipeline。本機檢查可以快速發現簡單錯誤；GitHub Actions 則作為正式的共同標準，確保所有推送到 repository 的程式都經過相同的 CI 規則。

我也使用故意製造錯誤的方式驗證 pipeline，例如格式錯誤、測試預期錯誤、TypeScript 型別錯誤。這樣可以確認 pipeline 不只是會在成功時顯示綠燈，也能在任何一項品質檢查失敗時正確顯示失敗，符合 spec 中「任一檢查失敗時，GitHub Actions pipeline 應顯示失敗」的要求。

## 5. 結論

本次 CI/CD 作業完成了 `.github/workflows/ci_111550006.yaml`，並讓 pipeline 在 push 與 pull request 時自動執行 TypeScript typecheck、Prettier check 和 Vitest test。透過分離 job 的設計，GitHub Actions 可以清楚呈現每一項檢查的結果；透過 artifact 上傳，也能保留測試報告供後續檢查。

從失敗案例可以看到，pipeline 能成功偵測格式錯誤、測試錯誤與 TypeScript 型別錯誤。這代表 CI pipeline 可以作為進入主要分支前的品質防線，協助團隊更早發現問題並降低人工檢查成本。
