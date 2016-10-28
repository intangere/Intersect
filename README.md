# Intersect
A small programming language written in nim named Intersect. The syntax is in Greek. <br>
The goal of this language is to write a small, fast, expandable language using a syntax based upon Greek words. <br>
The parser generates a pseudo AST which severely compresses the original code and allows for easier parsing. <br>
Example Intersect code is in : 
```
intersect.sct
```
<br>
The resulting raw AST of that code is:<br>
```
0system\n\n1test_module\ncx5\n2y1gy1dy2dy100dy900\n2z920x19ez0x120x29ez0x220x39ez0x3dz5dz3\n2q120x41fq0x420x52eq0x5gq520x6-5eq0x6\n6'x:'\n6x\n6'\n'\n6'y:'\n6y\n6'\n'\n6'z:'\n6z\n6'\n'\n6q\n3b45z6'The condition is true'51test_module@[@[0, system], @[
```
<br>
Here is the pretty-printed version:<br>
```
], @[
], @[1, test_module], @[
], @[c, x, 5], @[
], @[2, y, 1], @[g, y, 1], @[d, y, 2], @[d, y, 100], @[d, y, 900], @[
], @[2, z, 9], @[2, 0x1, 9], @[e, z, 0x1], @[2, 0x2, 9], @[e, z, 0x2], @[2, 0x3, 9], @[e, z, 0x3], @[d, z, 5], @[d, z, 3], @[
], @[2, q, 1], @[2, 0x4, 1], @[f, q, 0x4], @[2, 0x5, 2], @[e, q, 0x5], @[g, q, 5], @[2, 0x6, -5], @[e, q, 0x6], @[
], @[6, 'x:'], @[
], @[6, x], @[
], @[6, '\n'], @[
], @[6, 'y:'], @[
], @[6, y], @[
], @[6, '\n'], @[
], @[6, 'z:'], @[
], @[6, z], @[
], @[6, '\n'], @[
], @[6, q], @[
], @[3, b, 45, z], @[6, 'The condition is true'], @[5], @[1, test_module]]

```
