"""Second pass of the screenshot walk: ritual detail, catalogue, checkout, info pages.
Run after phone_walk.py, with the app signed in: python3 -I scripts/phone_walk_more.py"""
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from phone_walk import LOG, OUT, back, labels, shot, swipe_up, tap  # noqa: E402


def note(name):
    LOG.append(f"{name} labels: " + " | ".join(labels())[:420])


tap("Book", last=True, wait=3)
if tap("Rituals", wait=4):
    if tap("Karwa Chauth", wait=4):
        shot("12-ritual-detail")
        note("ritual detail")
        swipe_up()
        shot("12b-ritual-detail-lower")
        back()
    if tap("Browse rituals", wait=4):
        shot("19-catalogue")
        note("catalogue")
        swipe_up()
        shot("19b-catalogue-lower")
        if tap("₹299", wait=2) or tap("Select", wait=2):
            shot("20-catalogue-selected")
            if tap("Proceed to Payment", wait=4):
                shot("21-checkout")
                note("checkout")
                back()
        back()
    if tap("Add ritual", wait=4):
        shot("22-ritual-form")
        note("ritual form")
        back()
        tap("Discard", wait=2) or tap("Leave", wait=2)
    back()
tap("Profile", last=True, wait=3)
if tap("About Hamari Virasat", wait=4):
    shot("23-about")
    note("about")
    for label, name in [("FAQ", "24-faq"), ("Pricing", "25-pricing"), ("Contact", "26-contact"), ("How it works", "27-how-it-works")]:
        if tap(label, wait=3):
            shot(name)
            back()
    back()
if tap("Privacy & permissions", wait=3):
    shot("28-privacy")
    back()
if tap("Help for elders", wait=3):
    shot("29-help-for-elders")
    back()
tap("Home", last=True, wait=3)
print("\n".join(LOG))
