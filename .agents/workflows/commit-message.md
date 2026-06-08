---
description: how to write a commit message for this project
---

# Commit Message Convention

Dự án này dùng **Conventional Commits** style. Format:

```
<type>(<scope>): <short description>
```

## Types

| Type | Dùng khi |
|------|----------|
| `feat` | Thêm tính năng mới |
| `fix` | Sửa bug |
| `refactor` | Thay đổi code không liên quan đến feat/fix |
| `chore` | Công việc phụ (update deps, config, readme...) |
| `release` | Tạo release version mới |

## Scope (tuỳ chọn)

Dùng scope khi thay đổi chỉ ảnh hưởng đến một platform hoặc layer:

- `(ios)` – chỉ iOS
- `(android)` – chỉ Android
- `(js)` – chỉ JS/TS layer

Bỏ scope nếu thay đổi ảnh hưởng nhiều platform cùng lúc.

## Rules

1. Dùng tiếng Anh
2. Chữ thường, không dấu chấm cuối câu
3. Short description ≤ 72 ký tự
4. Không dùng dấu chấm than hay emoji trong message chính

## Ví dụ từ dự án

```
fix(ios): ensure toast overlays all screens
fix: improve toast keyboard handling on iOS
refactor: rename field
chore: upgrade nitro 0.25.2 -> 0.26.2
chore: update readme
release: [0.1.19]
```

## Đề xuất commit message

Khi được hỏi, hãy:
1. Xem `git log --oneline -10` để nắm style hiện tại
2. Tóm gọn thay đổi theo đúng format trên
3. Đề xuất 1 message ngắn + 1 message có body nếu thay đổi phức tạp
