from stats import moving_sum


def test_full_windows():
    assert moving_sum([1, 2, 3, 4], 2) == [3, 5, 7]


if __name__ == "__main__":
    test_full_windows()
    print("ok")
