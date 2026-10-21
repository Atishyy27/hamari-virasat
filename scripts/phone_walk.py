"""Drives the app on a USB-connected phone and saves a screenshot of every screen.

Run: python3 -I scripts/phone_walk.py            (walks the app as the demo family admin)
Finds buttons by their visible text through the accessibility tree, so no fixed coordinates.
Screenshots land in design/screenshots/.
"""
import os
import re
import subprocess
import sys
import time

ADB = os.path.expanduser("~/Library/Android/sdk/platform-tools/adb")
PKG = "in.hamarivirasat.hamari_virasat"
SERIAL = "RZ8R223Z6WK"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "design", "screenshots")
os.makedirs(OUT, exist_ok=True)
LOG = []


def adb(*args, timeout=40):
    """Runs adb, retrying when the USB link drops for a moment."""
    for _ in range(4):
        try:
            r = subprocess.run([ADB, "-s", SERIAL, *args], capture_output=True, timeout=timeout)
            if r.returncode == 0:
                return r.stdout.decode(errors="ignore")
        except subprocess.TimeoutExpired:
            pass
        subprocess.run([ADB, "-s", SERIAL, "wait-for-device"], capture_output=True, timeout=30)
        time.sleep(1)
    return ""


def in_front():
    return PKG in "".join(l for l in adb("shell", "dumpsys", "activity", "activities").splitlines()
                          if "ResumedActivity" in l)


def nodes():
    adb("shell", "uiautomator", "dump", "/data/local/tmp/ui.xml")
    xml = adb("shell", "cat", "/data/local/tmp/ui.xml")
    out = []
    for m in re.finditer(r"<node [^>]*>", xml):
        n = m.group(0)
        label = " ".join(re.findall(r'(?:text|content-desc)="([^"]*)"', n)).strip()
        b = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', n)
        if label and b:
            x1, y1, x2, y2 = map(int, b.groups())
            out.append((label.replace("&#10;", " ").replace("&amp;", "&"), (x1 + x2) // 2, (y1 + y2) // 2, (x2 - x1) * (y2 - y1)))
    return out


def labels():
    return [n[0] for n in nodes()]


def tap(text, wait=2.5, last=False):
    """Taps the smallest element whose label contains the text. Returns True if found."""
    if not in_front():
        LOG.append(f"NOT IN FRONT before tapping {text!r}")
        return False
    hits = [n for n in nodes() if text.lower() in n[0].lower()]
    if not hits:
        LOG.append(f"missing: {text!r}")
        return False
    hits.sort(key=lambda n: n[3])
    n = hits[-1] if last else hits[0]
    adb("shell", "input", "tap", str(n[1]), str(n[2]))
    time.sleep(wait)
    return True


def shot(name):
    if not in_front():
        LOG.append(f"NOT IN FRONT, no screenshot for {name}")
        return False
    adb("shell", "screencap", "-p", "/data/local/tmp/s.png")
    path = os.path.join(OUT, name + ".png")
    adb("pull", "/data/local/tmp/s.png", path)
    ok = os.path.exists(path) and os.path.getsize(path) > 20000
    LOG.append(f"{'shot' if ok else 'SHOT FAILED'} {name}")
    return ok


def back(wait=1.5):
    adb("shell", "input", "keyevent", "4")
    time.sleep(wait)


def swipe_up(wait=1.2):
    adb("shell", "input", "swipe", "540", "1700", "540", "700", "300")
    time.sleep(wait)


def main():
    if "--keep" not in sys.argv:
        adb("shell", "pm", "clear", PKG)
    adb("shell", "cmd", "statusbar", "collapse")
    adb("shell", "monkey", "-p", PKG, "-c", "android.intent.category.LAUNCHER", "1")
    time.sleep(1.2)
    if "--keep" not in sys.argv:
        shot("01-splash")
    time.sleep(4)
    if "--keep" not in sys.argv:
        shot("02-onboarding-1")
    if tap("Continue"):
        shot("03-onboarding-2")
        tap("Continue")
        shot("04-onboarding-3")
        tap("Begin Your Family Story")
    else:
        tap("Skip")
    time.sleep(1)
    if any("Verify" in l for l in labels()):
        shot("05-otp-login")
    LOG.append("login labels: " + " | ".join(labels())[:400])
    if not tap("Family admin", wait=7) and not any("Recent memories" in l for l in labels()):
        print("\n".join(LOG))
        sys.exit("could not find the demo login button, and the app is not on Home either")
    shot("06-home")
    LOG.append("home labels: " + " | ".join(labels())[:500])
    swipe_up()
    shot("07-home-lower")

    for tab, name in [("Family", "08-family"), ("Book", "10-book"), ("Profile", "16-profile")]:
        tap(tab, last=True, wait=3)
        shot(name)
        if tab == "Family":
            swipe_up()
            shot("09-family-members")
        if tab == "Book":
            LOG.append("book labels: " + " | ".join(labels())[:400])
            for chapter, cname in [("Rituals", "11-book-rituals"), ("Recipes", "13-book-recipes"),
                                   ("Stories", "14-book-stories"), ("Photo Albums", "15-book-photos")]:
                if tap(chapter, wait=4):
                    shot(cname)
                    if chapter == "Rituals":
                        LOG.append("rituals labels: " + " | ".join(labels())[:500])
                        if tap("Chatti", wait=4):
                            shot("12-ritual-detail")
                            swipe_up()
                            shot("12b-ritual-detail-lower")
                            back()
                    back()
        if tab == "Profile":
            LOG.append("profile labels: " + " | ".join(labels())[:500])
            swipe_up()
            shot("17-profile-lower")

    if not tap("Capture", last=True, wait=3):
        tap("Add Memory", wait=3)
    shot("18-add-memory")
    back()

    print("\n".join(LOG))
    print("saved in", OUT)


if __name__ == "__main__":
    main()
