_cache = {}


def _key(user_id):
    return f"user:{user_id}"


def save_user(user):
    _cache[_key(user["id"])] = user


def load_user(user_id):
    return _cache.get(_key(user_id))


def display_name(user_id):
    user = load_user(user_id)
    return user["first"] + " " + user["last"]
