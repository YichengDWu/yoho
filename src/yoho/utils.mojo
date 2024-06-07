fn lpad(s: String, n: Int, c: String = " ") -> String:
    return c * (n - len(s)) + s


fn rpad(s: String, n: Int, c: String = " ") -> String:
    return s + c * (n - len(s))


fn pad(s: String, l: Int, r: Int, c: String = " ") -> String:
    return rpad(lpad(s, l, c), r, c)
