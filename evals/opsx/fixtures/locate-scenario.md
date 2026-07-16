# 复选框定位场景（脚本化，勿改文件）

## CLI `instructions apply --json` 的 tasks[]
```json
[ { "id": "1", "description": "1.1 新增用户模型" },
  { "id": "2", "description": "1.2 补充单元测试" },
  { "id": "3", "description": "2.1 补充单元测试" } ]
```

## tasks.md 原文（行号）
```
1: ## 1. 后端
2: - [x] 1.1 新增用户模型
3: - [ ] 1.2 补充单元测试
4: ## 2. 前端
5: - [ ] 2.1 补充单元测试
6: - [ ] 2.2 页面接入
```

## subagent 返回的 completed[]
```json
[ { "taskId": "2", "task": "1.2 补充单测" },
  { "taskId": "3", "task": "2.1 补充单元测试" } ]
```
（注意 taskId "2" 的 task 文本与 CLI description 有漂移。）
