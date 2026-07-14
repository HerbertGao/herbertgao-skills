def get_users(page=1, page_size=20):
    if page < 1:
        page = 1
    return db.query(f"SELECT * FROM users LIMIT {page_size} OFFSET {(page-1)*page_size}")
