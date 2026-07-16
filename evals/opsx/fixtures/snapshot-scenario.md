# 脏基线场景（脚本化输出，勿真跑 git）

波次 1 已验收：`backend/auth.py` 新增了鉴权中间件并打勾。用户未提交。

## 波次 2 波首
- `git status --porcelain -uall`：
```
 M backend/auth.py
?? notes.txt
```
- 树快照 `BASE2 = git write-tree`（内容含波次 1 的 auth.py 实现）

## 波次 2 波末（组 B 返回后）
- `git status --porcelain -uall`：
```
 M backend/auth.py
 M frontend/app.tsx
?? notes.txt
```
- 树快照 diff（`git diff --name-only "$BASE2" "$(snap)"`）输出：
```
backend/auth.py
frontend/app.tsx
```
（组 B 的 filesChanged 只申报了 frontend/app.tsx。）
