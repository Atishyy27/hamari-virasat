"""Seeds the live backend with demo families, members, rituals, recipes and memories.

Run: set -a; . .secrets; set +a; python3 -I scripts/seed_demo.py
Safe to run again: every row has a fixed id and is upserted.
Needs SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_ACCESS_TOKEN (the last only to promote the super admin).
"""
import json
import os
import sys
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone

URL = os.environ["SUPABASE_URL"]
KEY = os.environ["SUPABASE_ANON_KEY"]
PW = "Virasat@2026"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMG = os.path.join(ROOT, "app", "assets", "images")


def call(method, path, token=None, body=None, headers=None, raw=None):
    h = {"apikey": KEY, "Content-Type": "application/json"}
    if token:
        h["Authorization"] = "Bearer " + token
    h.update(headers or {})
    data = raw if raw is not None else (json.dumps(body).encode() if body is not None else None)
    req = urllib.request.Request(URL + path, data=data, method=method, headers=h)
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            t = r.read().decode()
            return r.status, (json.loads(t) if t.strip() else None)
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:300]


def login_or_signup(email):
    s, d = call("POST", "/auth/v1/token?grant_type=password", body={"email": email, "password": PW})
    if s == 200:
        return d["access_token"], d["user"]["id"], False
    s, d = call("POST", "/auth/v1/signup", body={"email": email, "password": PW})
    if s != 200 or not d.get("access_token"):
        sys.exit(f"could not sign in or sign up {email}: {s} {d}")
    return d["access_token"], d["user"]["id"], True


def profile(token, uid):
    s, d = call("GET", f"/rest/v1/profiles?id=eq.{uid}&select=*", token)
    return d[0] if s == 200 and d else None


def upsert(token, table, rows):
    if not rows:
        return
    s, d = call("POST", f"/rest/v1/{table}", token, rows, {"Prefer": "resolution=merge-duplicates"})
    print(f"  {table}: {len(rows)} rows, http {s}" + ("" if s < 300 else f" {d}"))


def family_admin(email, name, family, details):
    token, uid, _ = login_or_signup(email)
    p = profile(token, uid)
    if not p:
        s, p = call("POST", "/rest/v1/rpc/register_family", token,
                    {"p_full_name": name, "p_family_name": family})
        if s != 200:
            sys.exit(f"register_family failed for {email}: {s} {p}")
    fid = p["family_id"]
    call("PATCH", f"/rest/v1/families?id=eq.{fid}", token, details)
    s, f = call("GET", f"/rest/v1/families?id=eq.{fid}&select=invite_code", token)
    return token, uid, fid, f[0]["invite_code"]


def ritual(rid, fid, title, category, phase, samagri, steps, roles, recipes):
    r = {"id": rid, "family_id": fid, "title": title, "category": category, "phase": phase,
         "samagri": "\n".join(samagri), "steps": "\n".join(steps), "relative_roles": "\n".join(roles),
         "audio_paths": []}
    rec = [{"id": f"{rid}_rec{i}", "ritual_id": rid, "family_id": fid, "name": n,
            "ingredients": "\n".join(ing), "method": "\n".join(m)} for i, (n, ing, m) in enumerate(recipes)]
    return r, rec


def main():
    print("demo family")
    tok, uid, fid, code = family_admin(
        "demo@example.com", "Ramesh Mishra", "Mishra Parivar",
        {"gotra": "Kashyap", "kuldevi": "Vindhyavasini Mata", "kuldevta": "Baba Vishwanath"})

    members = [("Ramesh Mishra", "Pita"), ("Sushila Mishra", "Dadi"), ("Anita Mishra", "Mata"),
               ("Suresh Tiwari", "Mama"), ("Kavita Mishra", "Bua"), ("Hariprasad Mishra", "Dada ji"),
               ("Ananya Mishra", "Beti"), ("Arjun Mishra", "Beta"), ("Sunita Tiwari", "Mami"),
               ("Mahesh Mishra", "Chacha"), ("Rekha Mishra", "Chachi"), ("Pooja Dubey", "Behen"),
               ("Vikas Dubey", "Jija ji"), ("Kamla Devi", "Nani")]
    upsert(tok, "family_members",
           [{"id": f"demo_m{i}", "family_id": fid, "name": n, "relation": r, "phone": ""}
            for i, (n, r) in enumerate(members)])

    R = []
    R.append(ritual("demo_r1", fid, "Chatti / Shashti Puja", "Child Birth (Sanskara)", "Chatti / Shashti Puja",
        ["Haldi, kumkum, akshat", "Naye kapde shishu ke liye", "Diya aur ghee", "Kajal ki dibbi"],
        ["Chhathe din shishu ko snan karaya jata hai", "Kuldevi ki puja hoti hai", "Bua kajal lagati hain", "Naamkaran hota hai"],
        ["Mama: naye kapde aur shagun lata hai", "Dadi: puja karwati hain", "Bua: kajal lagati hain"],
        [("Gud ki Kheer", ["Chawal 1 katori", "Doodh 1 litre", "Gud 200 gram", "Elaichi, kaju"],
          ["Chawal ko doodh me dheemi aanch par pakayein.", "Gaadha hone par aanch band karke gud milayein.", "Elaichi aur kaju se sajayein."]),
         ("Panjiri", ["Aata 2 katori", "Ghee 1 katori", "Gond, makhana, sonth", "Boora"],
          ["Aate ko ghee me sunehra bhunein.", "Gond aur makhana tal kar milayein.", "Thanda hone par boora milayein."])]))
    R.append(ritual("demo_r2", fid, "Haldi ki Rasam", "Boy Wedding (Var Paksha)", "Haldi",
        ["Haldi ki gaanth", "Sarson ka tel", "Doob ghaas", "Peela kapda"],
        ["Paanch suhagin haldi peesti hain", "Dulhe ko chowki par bithaya jata hai", "Pair se sir tak haldi lagayi jati hai", "Geet gaye jate hain"],
        ["Bhabhi: pehli haldi lagati hain", "Bua: aarti utarti hain", "Mama: imli ghotai ki rasam karte hain"],
        [("Besan ke Laddu", ["Besan 2 katori", "Ghee 1 katori", "Boora 1.5 katori"],
          ["Besan ko ghee me dheemi aanch par bhunein.", "Thanda karke boora milayein aur laddu bandhein."])]))
    R.append(ritual("demo_r3", fid, "Tilak Samaroh", "Boy Wedding (Var Paksha)", "Tilak",
        ["Roli, chawal", "Nariyal", "Mithai ka thaal", "Phal aur mewa"],
        ["Kanya paksh ke log var ke ghar aate hain", "Var ko chowki par bithakar tilak kiya jata hai", "Shagun aur uphar diye jate hain"],
        ["Kanya ke bhai: tilak lagate hain", "Pandit ji: mantra padhte hain", "Dada ji: ashirwad dete hain"], []))
    R.append(ritual("demo_r4", fid, "Annaprasan", "Annaprasan", "",
        ["Chandi ki katori aur chammach", "Kheer", "Phool mala"],
        ["Shubh muhurat me shishu ko god me bithaya jata hai", "Pehla niwala kheer ka khilaya jata hai", "Shishu ke saamne kalam, kitab aur sona rakha jata hai"],
        ["Mama: pehla niwala khilate hain", "Dadi: geet gaati hain"],
        [("Chawal ki Kheer", ["Chawal, doodh, cheeni", "Kesar"], ["Chawal ko doodh me galne tak pakayein.", "Cheeni aur kesar milayein."])]))
    R.append(ritual("demo_r5", fid, "GodBharai / Sadh", "Child Birth (Sanskara)", "",
        ["Laal chunri", "Saat prakar ke phal", "Mewa aur mishri", "Nariyal", "Choodiyan aur bindi"],
        ["Saatve mahine me shubh din chuna jata hai", "Hone wali maa ko chowki par bithaya jata hai", "Saas god me phal aur mewa bharti hain", "Suhagin mahilayein sohar gaati hain", "Sabko prasad baanta jata hai"],
        ["Saas: god bharti hain", "Nanad: kajal lagati hain", "Mayke wale: sadh ka saman late hain"],
        [("Meetha Dalia", ["Dalia 1 katori", "Gud", "Ghee", "Sukhe mewe"], ["Dalia ko ghee me bhunein.", "Pani me gala kar gud milayein.", "Mewe daal kar parosein."])]))
    R.append(ritual("demo_r6", fid, "Mundan Sanskar", "Mundan", "",
        ["Naya ustra", "Aate ki loi", "Haldi aur dahi", "Naye kapde"],
        ["Kuldevi ke sthan par jaya jata hai", "Bua aate ki loi me baal sametti hain", "Sir par haldi aur dahi ka lep lagta hai", "Baal nadi me pravahit kiye jate hain"],
        ["Bua: baal jhelti hain aur neg leti hain", "Nai: mundan karta hai", "Pita: sankalp lete hain"], []))
    R.append(ritual("demo_r7", fid, "Janeu / Upanayan", "Vidya Arambh", "",
        ["Janeu ke dhaage", "Peeli dhoti", "Palash ka dand", "Bhiksha ki jholi", "Havan samagri"],
        ["Batuk ka mundan hota hai", "Guru Gayatri mantra dete hain", "Batuk maa se pehli bhiksha maangta hai", "Havan aur ashirwad"],
        ["Guru: mantra deeksha dete hain", "Mata: pehli bhiksha deti hain", "Mama: batuk ko Kashi jaane se rokte hain"],
        [("Poori aur Aloo ki Sabzi", ["Aata", "Aloo", "Tamatar", "Hing, jeera"], ["Bina pyaz lehsun ki sabzi banayein.", "Garam poori ke saath parosein."])]))
    R.append(ritual("demo_r8", fid, "Chhath Puja", "Festival", "",
        ["Baans ka soop aur daura", "Thekua", "Ganna", "Kela aur nariyal", "Mitti ke diye"],
        ["Pehla din: Nahay Khay", "Doosra din: Kharna, gud ki kheer ka prasad", "Teesra din: doobte Surya ko arghya", "Chautha din: ugte Surya ko arghya aur paran"],
        ["Vrati: 36 ghante ka nirjala vrat rakhti hain", "Ghar ke purush: daura sir par ghat tak le jate hain", "Bachche: ghat sajate hain"],
        [("Thekua", ["Gehun ka aata 2 katori", "Gud 1 katori", "Ghee", "Saunf, nariyal"], ["Gud ko pani me ghol kar aata goondhein.", "Saanche se aakar dekar ghee me talein."]),
         ("Kharna ki Kheer", ["Arwa chawal", "Gud", "Doodh"], ["Mitti ke chulhe par aam ki lakdi se pakayein.", "Gud aanch se utaar kar milayein."])]))
    R.append(ritual("demo_r9", fid, "Ganapati Puja", "Festival", "",
        ["Ganesh ji ki mitti ki murti", "Durva ghaas", "Laal phool", "Modak", "Sindoor"],
        ["Murti ki sthapana", "Pran pratishtha aur shodashopachar puja", "Subah shaam aarti", "Visarjan"],
        ["Dada ji: sthapana karte hain", "Bachche: aarti gaate hain", "Mata: modak banati hain"],
        [("Ukadiche Modak", ["Chawal ka aata", "Taza nariyal", "Gud", "Elaichi"], ["Nariyal aur gud ka pooran banayein.", "Chawal ke aate ki lohi me bhar kar bhaap me pakayein."])]))
    R.append(ritual("demo_r10", fid, "Navratri aur Kanya Pujan", "Festival", "",
        ["Kalash aur nariyal", "Jau", "Laal chunri", "Akhand jyot ke liye ghee", "Kanyaon ke liye uphar"],
        ["Pratipada ko ghat sthapana aur jau bona", "Nau din Durga Saptashati ka paath", "Ashtami ko havan", "Navami ko nau kanyaon ka pujan aur bhoj"],
        ["Dadi: paath karti hain", "Pita: akhand jyot ka dhyan rakhte hain", "Mata: kanya bhoj banati hain"],
        [("Sooji ka Halwa", ["Sooji", "Ghee", "Cheeni", "Pani"], ["Sooji ko ghee me bhunein.", "Chashni milakar gaadha karein."]),
         ("Kale Chane", ["Kale chane", "Jeera", "Amchur"], ["Chane raat bhar bhigo kar ubaalein.", "Sookhe masale me chhaunk lagayein."])]))
    R.append(ritual("demo_r11", fid, "Karwa Chauth", "Festival", "",
        ["Mitti ka karwa", "Chhalni", "Sargi ki thaali", "Solah shringar", "Deepak"],
        ["Subah sargi khayi jati hai", "Din bhar nirjala vrat", "Shaam ko katha suni jati hai", "Chaand ko chhalni se dekh kar arghya", "Pati ke haath se pani pee kar vrat khola jata hai"],
        ["Saas: sargi deti hain", "Bahu: baya deti hain", "Pati: vrat khulwate hain"],
        [("Pheni", ["Pheni", "Doodh", "Cheeni", "Kesar"], ["Doodh ko ubaal kar cheeni milayein.", "Pheni daal kar turant parosein."])]))
    R.append(ritual("demo_r12", fid, "Hariyali Teej", "Festival", "",
        ["Hare kapde aur choodiyan", "Mehndi", "Jhoola", "Ghewar"],
        ["Mayke se sindhara aata hai", "Mehndi lagayi jati hai", "Jhoola jhoolte hue geet gaye jate hain", "Parvati ji ki puja"],
        ["Mata: sindhara bhejti hain", "Saheliyan: geet gaati hain"],
        [("Ghewar", ["Maida", "Ghee", "Thanda doodh", "Chashni"], ["Patla ghol bana kar garam ghee me dhaar se daalein.", "Chashni me dubo kar rabdi se sajayein."])]))
    R.append(ritual("demo_r13", fid, "Diwali Lakshmi Pujan", "Festival", "",
        ["Lakshmi Ganesh ki murti", "Kheel batashe", "Mitti ke diye", "Kamal ka phool", "Naye bahi khate"],
        ["Ghar ki safai aur rangoli", "Pradosh kaal me puja", "Bahi khaton ki puja", "Pehla diya Kuldevta ke sthan par", "Poore ghar me diye"],
        ["Dada ji: puja karwate hain", "Bachche: diye sajate hain", "Mata: rangoli banati hain"],
        [("Gujiya", ["Maida", "Khoya", "Sukhe mewe", "Cheeni"], ["Khoya bhun kar mewe aur cheeni milayein.", "Maide ki poori me bhar kar talein."])]))
    R.append(ritual("demo_r14", fid, "Bhai Dooj", "Festival", "",
        ["Roli chawal", "Nariyal", "Mithai", "Kalava"],
        ["Behen chowk poorti hai", "Bhai ko tilak laga kar aarti", "Bhai uphar deta hai", "Chitragupta ji ki kalam dawat ki puja"],
        ["Behen: tilak karti hai", "Bhai: raksha ka vachan deta hai"], []))
    upsert(tok, "rituals", [r for r, _ in R])
    upsert(tok, "recipes", [x for _, rec in R for x in rec])

    now = datetime.now(timezone.utc)
    stories = [
        ("Diwali at Dadi's old home", "Har saal poora parivar Dadi ke purane ghar me ikattha hota tha. Aangan me rangoli banti thi aur raat ko sab milkar diye jalate the.", ["Diwali", "Dadi", "Festival"], 2),
        ("Dadaji ki kahaniyan", "Garmi ki chhuttiyon me chhat par sote waqt Dadaji gaon ki kahaniyan sunate the.", ["Dadaji", "Kuldevi"], 9),
        ("Nani ke haath ka achaar", "Nani har garmi me aam ka achaar daalti thi. Martbaan dhoop me rakhe jate the aur hum bachche chori se chakhte the.", ["Nani", "Recipe"], 14),
        ("Papa ki pehli cycle", "1978 me Papa ne apni pehli tankhwah se Atlas cycle kharidi thi. Wo aaj bhi gaon ke ghar me rakhi hai.", ["Papa", "1978"], 21),
        ("Kuldevi ke mandir ki yatra", "Har bachche ka mundan Vindhyachal me hota hai. Poora parivar do din pehle pahunch jata hai.", ["Kuldevi", "Yatra"], 30),
        ("Bua ki shaadi", "1992 ki sardiyon me Bua ki shaadi hui thi. Baraat teen din ruki thi aur poore mohalle ne khana banaya tha.", ["Shaadi", "1992"], 45),
        ("Sohar jo Dadi gaati thi", "Jab bhi ghar me bachcha hota, Dadi ye sohar gaati thi. Humne iske bol likh liye hain.", ["Sohar", "Dadi", "Geet"], 60),
        ("Gaon ka purana ghar", "Mitti ka aangan, neem ka ped aur kuan. Wo ghar ab nahi raha, par uski yaadein yahan hain.", ["Gaon", "Ghar"], 75),
        ("Maa ka pehla Karwa Chauth", "Maa batati hain ki pehle Karwa Chauth par chaand badalon me chhup gaya tha aur raat ke gyarah baj gaye the.", ["Karwa Chauth", "Maa"], 90),
        ("Chacha ki fauj ki chitthiyan", "Chacha border se har mahine chitthi likhte the. Dadi ne sab sambhal kar rakhi hain.", ["Chacha", "Chitthi"], 120),
        ("Holi ka phaag", "Holi par mohalle ke log dholak lekar aate the aur ghanton phaag gaya jata tha.", ["Holi", "Geet"], 150),
        ("Pehli baar Chhath ghat par", "Bachpan me pehli baar subah ke arghya ke liye ghat par gaye the. Thand me kaanpte hue Maa ka aanchal pakda tha.", ["Chhath", "Bachpan"], 200),
    ]
    mem = [{"id": f"demo_mem{i + 1}", "family_id": fid, "kind": "story", "title": t, "story": s, "tags": tags,
            "media_paths": [], "created_by_name": "Ramesh Mishra",
            "created_at": (now - timedelta(days=d)).isoformat()} for i, (t, s, tags, d) in enumerate(stories)]

    photos = [("Poora parivar aangan me", "onboard_roots.png", ["Parivar", "Aangan"], 5, "Shaadi ke baad ki pehli family photo, purane ghar ke aangan me."),
              ("Dadi aur Ananya, album dekhte hue", "onboard_memories.png", ["Dadi", "Album"], 12, "Dadi purani tasveeron ki kahani suna rahi hain."),
              ("Tyohaar ka bhoj", "onboard_traditions.png", ["Bhoj", "Diwali"], 18, "Diwali ki raat ka khana, sab ek saath."),
              ("Diwali 1987", "memory_diwali.png", ["Diwali", "1987"], 40, "Dadi ke purane ghar ki Diwali."),
              ("Navratri ka kanya bhoj", "onboard_traditions.png", ["Navratri", "Bhoj"], 65, "Navami ke din nau kanyaon ka bhoj."),
              ("Rangoli wali subah", "onboard_roots.png", ["Rangoli", "Tyohaar"], 100, "Aangan ki rangoli ke saath sab.")]
    for i, (title, img, tags, d, story) in enumerate(photos):
        mid = f"demo_photo{i + 1}"
        path = f"{fid}/{mid}/{img}"
        with open(os.path.join(IMG, img), "rb") as f:
            s, r = call("POST", f"/storage/v1/object/memories/{path}", tok, raw=f.read(),
                        headers={"Content-Type": "image/png", "x-upsert": "true"})
        if s >= 300:
            print(f"  photo upload {img}: http {s} {r}")
        mem.append({"id": mid, "family_id": fid, "kind": "photo", "title": title, "story": story, "tags": tags,
                    "media_paths": [path], "created_by_name": "Ramesh Mishra",
                    "created_at": (now - timedelta(days=d)).isoformat()})
    upsert(tok, "memories", mem)

    print("member of the demo family")
    mtok, muid, new = login_or_signup("member@example.com")
    if not profile(mtok, muid):
        s, d = call("POST", "/rest/v1/rpc/join_family", mtok, {"p_full_name": "Ananya Mishra", "p_invite_code": code})
        print(f"  join_family http {s}" + ("" if s == 200 else f" {d}"))

    print("two more families, so the super admin list is not empty")
    for email, name, fam, det in [
        ("sharma@example.com", "Rajiv Sharma", "Sharma Parivar", {"gotra": "Bharadwaj", "kuldevi": "Sheetla Mata", "kuldevta": "Hanuman ji"}),
        ("verma@example.com", "Sunil Verma", "Verma Parivar", {"gotra": "Vatsa", "kuldevi": "Jwala Devi", "kuldevta": "Bhairav Baba"}),
    ]:
        t, u, f2, _ = family_admin(email, name, fam, det)
        key = fam.split()[0].lower()
        upsert(t, "family_members", [{"id": f"{key}_m{i}", "family_id": f2, "name": n, "relation": r, "phone": ""}
                                     for i, (n, r) in enumerate([(name, "Pita"), ("Meera " + fam.split()[0], "Mata"), ("Arjun " + fam.split()[0], "Beta")])])
        r, rec = ritual(f"{key}_r1", f2, "Griha Pravesh", "Festival", "", ["Kalash", "Aam ke patte", "Havan samagri"],
                        ["Dwar puja", "Kalash sthapana", "Havan", "Doodh ubaalna"], ["Grihini: kalash lekar pehle pravesh karti hain"], [])
        upsert(t, "rituals", [r])

    print("super admin")
    stok, suid, _ = login_or_signup("super@example.com")
    mgmt = os.environ.get("SUPABASE_ACCESS_TOKEN")
    if mgmt:
        sql = ("insert into public.profiles (id, full_name, email, role) values "
               f"('{suid}', 'Platform Admin', 'super@example.com', 'super_admin') "
               "on conflict (id) do update set role = 'super_admin', family_id = null returning role")
        req = urllib.request.Request(
            "https://api.supabase.com/v1/projects/" + URL.split("//")[1].split(".")[0] + "/database/query",
            data=json.dumps({"query": sql}).encode(), method="POST",
            headers={"Authorization": "Bearer " + mgmt, "Content-Type": "application/json", "User-Agent": "seed"})
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                print("  promote:", r.read().decode()[:120])
        except urllib.error.HTTPError as e:
            print("  promote failed:", e.code, e.read().decode()[:200])

    for table in ("family_members", "rituals", "recipes", "memories"):
        s, d = call("GET", f"/rest/v1/{table}?select=id", tok)
        print(f"demo family {table}: {len(d) if s == 200 else d}")


main()
