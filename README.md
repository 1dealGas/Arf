# Arf

Aerials Chart(Fumen) Generator, Compiler and Viewer.

Product Features:

- **Script-Style Chart(Fumen) Designing**, with Bartime and Method Chaining

- Detailed Preprocessing Steps for **Highly Performant Output**

- **Export Chart(Fumen) Result as Ready-for-Use Lua Script**

- File Listening, Audio Seeking and Slow-Play Support

## Usage

1. Download the whole Project, Import it into your Godot Editor(v4.2 dev3 or above) and **Edit** it.

2. Open `〈Arf〉.tscn`, change "**Stream**" property of the Root Node "Arf" (or just add `〈Audio〉.ogg` into your Project).

3. Write your chart in the function body of `〈Fumen〉.gd`.

4. Run Arf **in debug mode** to view your work.
   
   -- Changes of `〈Fumen〉.gd` will be synchronized to the viewer automatically.

5. Click the button **"ExportButton"** to get the final `*.ar` file.

## Credit

- Included 2 Icons from **ByteDance IconPark** ([Website](https://iconpark.oceanengine.com/home) · [GitHub](https://github.com/bytedance/iconpark)), Licensed under the [Apache License 2.0](https://github.com/bytedance/IconPark/blob/master/LICENSE)

- Interim Map Format Inspired from **aerials-writer** ([GitHub](https://github.com/Fuxfantx/aerials-writer) · [Initiator](https://github.com/zarmot))

---

---

## API Reference

Organized according to the steps to write an Aerials Map.

---

### Song Config

`Madeby(author:String)`

--  Specify Author's name to be displayed of this map.

--  the AutherName should comply with one of the formats below, according to the map's difficulty (Assuming that the Map is made by "ARFUSER"):

`·····  ARFUSER`    `··|··  ARFUSER`    `·|·|·  ARFUSER`    `·|·|·  ARFUSER`

`||·||  ARFUSER`    `|||||  ARFUSER`    `||◇||  ARFUSER`

---

`Offset(ms:int)`

--  Specify the ms position of `Bar 0` .

--  **Negative Offset Value is not recommended**.

---

`BPM(arr:Array[float])`

--  Specify Tempo information of the song with `BarTime` Value and `4/4 Beats Per Minute` Value, permuted in turn.

--  Example:

```gdscript
func fumen():
    BPM([
        0, 185,        # In Bar0 - Bar16, the 4/4 BPM is 185
        16, 370        # In Bar16 - The End Bar, the 4/4 BPM is 370
    ])
```

---

### Z-Layer System Related

`forz(z:int)`

--  Specify the Z-Layer you work on.

--  Z-Layer should be ranged in {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16}. By default, Arf works on the Z-Layer 1.

--  Respective SV&Camera Rules are applied to `Wish`es and `Hint`s in respective Z-Layers.

---

`DTime(arr:Array[float])`

--  Specify the Speed Variation Rules for the current Z-Layer. SV Effects only affect the movement of `Wish`es, rather than `Hint`s.

--  SV Rules extends to ALL `Wish`es in its respective Z-Layer.

--  Example:

```gdscript
func fumen():
    DTime([
        0,1,    # In Bar0-Bar10, Wishes flow at a normal speed
        10,2,   # In Bar10-Bar20, Wishes flow at a 2x speed
        20,0.5, # In Bar20-Bar30, Wishes flow at a 0.5x speed
        30,-1   # In B30-The End Bar, Wishes flow at a 1x speed reversely
    ])
```

--  You may nullify the SV Rule with the command `DTime([])` , rather than `DTime([0,1])` .

--  For SV Rules Array that doesn't begin at Bar 0, a default [0,1] line will be added automatically.

---

`XScale(arr:Array[CamNode])` `YScale(arr:Array[CamNode])` `Rotrad(arr:Array[CamNode])` `XDelta(arr:Array[CamNode])` `YDelta(arr:Array[CamNode])`

--  Specify the Camera Variation Rules for the current Z-Layer. SV Effects only affect the movement of `Wish`es, rather than `Hint`s.

--  Transformation Rrder of Aerials' Camera System is  **Zoom  ->  Rotate  ->  Translate** . For the rotation process, the pivot is the center of your screen, and the direction is counterclockwise.

--  Recommended to Use the method `c(Ninitbt:float, Nvalue:float, Neasetype:int=0)` to create `CamNode` objects, rather than creating them manually.

--  Example:

```gdscript
func fumen():
    Rotrad([

        # The rotation begins at Bar 15, with linear easing.
        c(15,0,0),

        # At Bar 50, the camera's been rotated by 180° counterclockwisely.
        c(50,-pi,0)

    ])
```

--  The default `Scale` Value is `1` (means 1.0x).  `0` for `Rotrad` & `Delta` Values.

---

### Easing System Related

---

### Manipulate Aerials' Basic Elements

`w(x:float, y:float, bartime:float, easetype:int=0, zdelta:float=0)`
