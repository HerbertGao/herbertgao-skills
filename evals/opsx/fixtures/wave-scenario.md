# 波次 1 返回与地面真相（脚本化场景，勿真跑 git）

## 派发给组 A 的任务集
- id "1"：实现 /api/users 端点
- id "2"：为端点补集成测试

## subagent 返回（JSON）
```json
{
  "group": "A — 后端",
  "schema": "spec-driven",
  "completed": [ { "taskId": "1", "task": "实现 /api/users 端点" },
                 { "taskId": "2", "task": "为端点补集成测试" } ],
  "incomplete": [],
  "filesChanged": [ { "path": "/repo/backend/users.py", "summary": "新端点" },
                    { "path": "/repo/backend/tests/test_users.py", "summary": "集成测试" } ],
  "issues": [],
  "needsAttention": false
}
```

## 主 agent 自己跑出的地面真相
- 波首 HEAD：a1b2c3d；波末 `git rev-parse HEAD`：a1b2c3d（未漂移）
- 树快照 diff（`git diff --name-only "$BASE" "$(snap)"`）输出：
```
backend/users.py
```
