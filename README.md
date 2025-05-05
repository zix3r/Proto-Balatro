# Proto-Balatro (LÖVE 2D Prototipas)

Paprastas Balatro žaidimo įkvėptas prototipas, sukurtas naudojant LÖVE 2D žaidimų variklį ir Lua programavimo kalbą. Projektas buvo vystomas porinio programavimo metodu su AI asistentu.

## Reikalavimai

-   [LÖVE 2D](https://love2d.org/) (testuota su 11.x versija)

## Technologijos

-   **Žaidimo variklis:** [LÖVE 2D](https://love2d.org/) (v11.x)
-   **Programavimo kalba:** Lua
-   **Pagalba:** AI Asistentas (porinis programavimas)

## Kaip paleisti žaidimą

1.  **Įsitikinkite, kad LÖVE 2D yra įdiegta** ir pasiekiama per komandinę eilutę arba žinote, kur yra `love` vykdomasis failas.
2.  **Atsidarykite** šio projekto aplanką (`Prototipas`).
3.  **Paleiskite vienu iš būdų:**
    *   **Komandinė eilutė:** Atsidarykite terminalą `Prototipas` aplanke ir įveskite:
        ```bash
        love .
        ```
    *   **Tempimas (Drag and Drop):** Nutempkite `Prototipas` aplanką ant `love.exe` (Windows), `love.app` (macOS), ar `love` (Linux) failo.
    *   **(Alternatyva) Sukurti `.love` failą:**
        *   Suarchyvuokite *turinį* `Prototipas` aplanko (t.y., `main.lua`, `card.lua` ir kiti `.lua` failai bei `cards` aplankas turi būti archyvo šaknyje).
        *   Pervadinkite gautą `.zip` failą į `Proto-Balatro.love`.
        *   Paleiskite `.love` failą per komandinę eilutę (`love Proto-Balatro.love`) arba nutempdami jį ant LÖVE vykdomojo failo.

## Kaip žaisti

**Tikslas:** Surinkti 2000 taškų per 4 rankų sužaidimus (angl. *plays*).

**Eiga:**
1.  Žaidimas prasideda su 10 kortų rankoje, 4 leidžiamais sužaidimais ir 2 leidžiamais kortų išmetimais (angl. *discards*).
2.  **Pasirinkite kortas:** Spustelėkite 1-5 kortas rankoje, kurias norėsite žaisti arba išmesti. Virš rankos matysite pasirinktos kombinacijos pavadinimą, bazinius taškus (chips) ir daugiklį (mult).
3.  **(Pasirinktinai) Rūšiavimas:** Galite spausti "Rūšiuoti pagal rangą" arba "Rūšiuoti pagal eilę" mygtukus, kad pertvarkytumėte kortas rankoje.
4.  **(Pasirinktinai) Kortų išmetimas:** Pasirinkę kortas, kurias norite išmesti (ne daugiau 5), spauskite "Išmesti kortas". Pasirinktos kortos bus pašalintos, o vietoj jų gausite naujas iš kaladės. Tai galite daryti iki 2 kartų per raundą. Išmetimai nesumažina leidžiamų sužaisti rankų skaičiaus.
5.  **Rankos žaidimas:** Pasirinkę 1-5 kortas, kurias norite žaisti, spauskite "Žaisti ranką".
6.  **Taškų skaičiavimas:** Jūsų ranka įvertinama, apskaičiuojami taškai (kombinacijos baziniai taškai + žaistų kortų taškai) padauginti iš daugiklio (kombinacijos bazinis daugiklis + Džokerių efektai). Taškai pridedami prie bendro rezultato (rezultatas viršuje kairėje animuotai pasipildo), o leidžiamų sužaisti rankų skaičius sumažėja vienetu.
7.  Sužaista ranka trumpai parodoma ekrano centre.
8.  Jūsų ranka papildoma iki 10 kortų iš kaladės (jei kaladė tuščia, permaišoma išmestų kortų krūva).
9.  Kartokite nuo 2 žingsnio.

**Pergalė ir Pralaimėjimas:**
*   **Laimite:** jei surenkate 2000 ar daugiau taškų.
*   **Pralaimite:** jei nesurenkate 2000 taškų per 4 leidžiamus sužaidimus.

**Valdymas:**
*   **Pelės kairys mygtukas:** Pasirinkti/atžymėti kortas, spausti mygtukus.
*   **ESC:** Uždaryti žaidimą. 
