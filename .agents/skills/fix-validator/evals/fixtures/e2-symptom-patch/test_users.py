from users import save_user, display_name


def test_display_name():
    save_user({"id": 7, "first": "Ada", "last": "Lovelace"})
    assert display_name(7) == "Ada Lovelace"


if __name__ == "__main__":
    test_display_name()
    print("ok")
