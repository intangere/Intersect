import strutils
import sequtils
import tables
import macros
import os

var IF = "\xce\xb1\xce\xbd" #αν
var ELSE = "\xce\xb1\xce\xbb\xce\xbb\xce\xbf\xcf\x8d" #αλλού
var DO = "\xce\xba\xce\xac\xce\xbd\xcf\x89"
var END = "\xcf\x84\xce\xad\xce\xbb\xce\xbf\xcf\x82"
var PUT = "\xce\xb2\xce\xac\xce\xb6\xcf\x89"
var USE = "\xcf\x87\xcf\x81\xce\xae\xcf\x83\xce\xb7"
var SPLIT = "\xcf\x83\xcf\x80\xce\xbb\xce\xb9\xcf\x84"
var FOR = "\xce\xb3\xce\xb9\xce\xb1"
var WHILE = "\xce\xb5\xce\xbd\xcf\x8e"
var BACKGROUND = "\xcf\x86\xcf\x8c\xce\xbd\xcf\x84\xce\xbf"
var ENTRY = "\xce\xb5\xce\xaf\xcf\x83\xce\xbf\xce\xb4\xce\xbf\xcf\x82"
var UNIT = "\xce\xbc\xce\xbf\xce\xbd\xce\xac\xce\xb4\xce\xb1"
var SOL = "\\"
var EOL = "\n"
var AST: seq[seq[string]] = @[]

var AST_LOOKUP = {
    IF : "3",
    ELSE : "4",
    DO : nil,
    END : "5",
    PUT : "6",
    USE : "0",
    SPLIT : "9",
    FOR : "7",
    WHILE : "8",
    BACKGROUND : "a",
    ENTRY : "2",
    UNIT : "1"

}.toTable

var AST_ORDER:seq[string] = @["**", "*", "/", "+", "-", ""]

var operators = {
    "+" : "d",
    "=" : "c",
    "==" : "b",
    "*" : "e",
    "/" : "f",
    "-" : "g",
    "**" : "p",
    "<>" : "j",
    "++" : "h",
    "--" : "i",
    "%" : "k", #Modulo add sin,cos,tan
}.toTable

var memory = initTable[string, string]()

var memory_pointer = 0x00000000

var block_started = false
var current_ast_stmt = 0

var current_path = ""

proc gen_unit(tokens: seq[string]) = 
  add(AST, @[AST_LOOKUP[tokens[tokens.len - 2]], tokens[tokens.len - 1]])

# x = 1 + ( 1 / 4 ) * ( 3 ** 5 ) 
# mov x, add(1, mul(pow(3, 5), 1/4))
# 0 x a 1 m p 3 5 1/4
#mov x, 0
#add x, 1
#mov avs, 1/4
#mov avz, 3 ** 5
#mul avs, avz
#add x, avs


proc gen_mem(pointer: int): string = 
  return "$#$#" % ["0x", intToStr(pointer)]

proc gen_expr_ast(tokens: seq[string]) =
  var opers = ["**", "/", "*", "+", "-"]
  var c = 0
  var v = tokens[1]
  var clean_tokens = tokens[3..tokens.len - 1]
  var in_mem = false
  for x in clean_tokens:
    if x in opers:
      case x:
        of "+":
          if not in_mem:
            in_mem = true
            add(AST, @[AST_LOOKUP[ENTRY], v, clean_tokens[c - 1]])
          add(AST, @[operators[x], v, clean_tokens[c + 1]])
        of "-":
          if not in_mem:
            in_mem = true
            add(AST, @[AST_LOOKUP[ENTRY], v, clean_tokens[c - 1]])
          add(AST, @[operators[x], v, clean_tokens[c + 1]])
        of "*":
          if not in_mem:
            in_mem = true
            add(AST, @[AST_LOOKUP[ENTRY], v, clean_tokens[c - 1]])
          memory_pointer += 1
          add(AST, @[AST_LOOKUP[ENTRY], gen_mem(memory_pointer), clean_tokens[c + 1]])
          add(AST, @[operators[x], v, gen_mem(memory_pointer)])
        of "/":
          if not in_mem:
            in_mem = true
            add(AST, @[AST_LOOKUP[ENTRY], v, clean_tokens[c - 1]])
          memory_pointer += 1
          add(AST, @[AST_LOOKUP[ENTRY], gen_mem(memory_pointer), clean_tokens[c + 1]])
          add(AST, @[operators[x], v, gen_mem(memory_pointer)])
    c += 1

proc gen_entry(tokens: seq[string]) = 
  if tokens.len == 4:
    add(AST, @[operators[tokens[2]], tokens[1], tokens[3]])
  else:
    gen_expr_ast(tokens)

proc gen_if(tokens: seq[string]) =
  add(AST, @[AST_LOOKUP[IF], operators[tokens[2]], tokens[1], tokens[3]])
  block_started = true

proc gen_put(tokens: seq[string]) =
  add(AST, @[AST_LOOKUP[PUT], join(tokens[1..tokens.len - 1], " ")])

proc gen_end(tokens: seq[string]) =
  add(AST, @[AST_LOOKUP[END]])
  discard #End scope somehow

proc do_use(tokens: seq[string]) = 
  discard

proc do_unit(tokens: seq[string]) = 
  discard

proc do_entry(tokens: seq[string]) = 
  memory[tokens[1]] = tokens[2]

proc do_if(tokens: seq[string]) =
  if memory.hasKey(tokens[2]) and memory.hasKey(tokens[3]):
    if memory[tokens[2]] != memory[tokens[3]]:
      current_ast_stmt  = current_ast_stmt + 1
  elif memory.hasKey(tokens[2]):
    if memory[tokens[2]] != tokens[3]:
      current_ast_stmt  = current_ast_stmt + 1
  elif memory.hasKey(tokens[3]):
    if memory[tokens[3]] != tokens[2]:
      current_ast_stmt  = current_ast_stmt + 1
  else:
    if tokens[3] != tokens[2]:
      current_ast_stmt  = current_ast_stmt + 1

proc do_put(tokens: seq[string]) =
  var to_put = join(tokens[1..tokens.len - 1], " ")
  if to_put.count("'") < 2:
    stdout.write memory[tokens[1]]
  else:
    stdout.write to_put.replace("\\n", "\n")[1..to_put.len - 1]

proc do_end(tokens: seq[string]) =
  block_started = false
  discard #End scope somehow

proc do_add(tokens: seq[string]) = 
  if tokens[2].startsWith("0x"):
    memory[tokens[1]] = formatFloat(parseFloat(memory[tokens[1]]) + parseFloat(memory[tokens[2]]))
  else:
    var pointer = parseFloat(memory[tokens[1]])
    memory[tokens[1]] = formatFloat(pointer + parseFloat(tokens[2]))

proc do_mul(tokens: seq[string]) = 
  memory[tokens[1]] = formatFloat(parseFloat(memory[tokens[1]]) * parseFloat(memory[tokens[2]]))

proc do_div(tokens: seq[string]) = 
  memory[tokens[1]] = formatFloat(parseFloat(memory[tokens[1]]) / parseFloat(memory[tokens[2]]))

proc do_sub(tokens: seq[string]) = 
  var pointer = parseFloat(memory[tokens[1]])
  memory[tokens[1]] = formatFloat(pointer - parseFloat(tokens[2]))

var GEN_AST_FUNCS = {
    UNIT : gen_unit,
    ENTRY : gen_entry,
    IF : gen_if,
    PUT : gen_put,
    END : gen_end,
    "kek" : gen_put
}.toTable

proc gen_use(tokens: seq[string]) = 
  if tokens[1] != "system":
    if existsFile "$#$#.isf" % [current_path, tokens[1]]:
      var syntax = readFile("$#$#.isf" % [current_path, tokens[1]])
      for x in syntax.split("\n"):
          if ":" in x:
            var atom = x.split(":")
            case atom[0]:
              of "IF":
                AST_LOOKUP[atom[1]] = AST_LOOKUP[IF]
                GEN_AST_FUNCS[atom[1]] = GEN_AST_FUNCS[IF]
              of "ELSE":
                ELSE = atom[1]
              of "DO":
                DO = atom[1]
              of "END":
                AST_LOOKUP[atom[1]] = AST_LOOKUP[END]
                GEN_AST_FUNCS[atom[1]] = GEN_AST_FUNCS[END]
              of "PUT":
                AST_LOOKUP[atom[1]] = AST_LOOKUP[PUT]
                GEN_AST_FUNCS[atom[1]] = GEN_AST_FUNCS[PUT]
              of "SPLIT":
                SPLIT = atom[1]
              of "FOR":
                FOR = atom[1]
              of "WHILE":
                WHILE = atom[1]
              of "BACKGROUND":
                BACKGROUND = atom[1]
              of "ENTRY":
                AST_LOOKUP[atom[1]] = AST_LOOKUP[ENTRY]
                GEN_AST_FUNCS[atom[1]] = GEN_AST_FUNCS[ENTRY]
              of "UNIT":
                UNIT = atom[1]
              of "SOL":
                SOL = atom[1]
              of "EOL":
                EOL = atom[1]
         # if atom[0] == "IF"
    else:
      echo "Intersect: Could not load syntax file for use case $#" % tokens[1]
      echo "System exited."
      quit(QuitFailure)
  add(AST, @[AST_LOOKUP[tokens[0]], tokens[1]])

var AST_FUNCS = {
    "0" : do_use,
    "1" : do_unit,
    "2" : do_entry,
    "3" : do_if,
    "6" : do_put,
    "5" : do_end,
    "c" : do_entry,
    "kek" : do_use,
    "d" : do_add,
    "g" : do_sub,
    "e" : do_mul,
    "f" : do_div
}.toTable

proc enumerateToAst(tokens: seq) = 
  var i = 0
  for token in tokens:
    if AST_LOOKUP.hasKey(token):
        if token == USE:
          gen_use(tokens)
        else:
          var k = GEN_AST_FUNCS[token]
          k(tokens)
    else:
        #echo "[Intersect]: Undefined atom at $#: $#" % [$i, token] 
        #returnd
        discard
    i = i + 1
  if block_started == false:
    add(AST, @[EOL])

proc evalAst() =
  while current_ast_stmt < AST.len:
    var stmt = AST[current_ast_stmt]
    if stmt != @["\n"]:
      AST_FUNCS[stmt[0]](stmt)
    current_ast_stmt = current_ast_stmt + 1

proc tokenize(line: string) = 
  var splits = split(line, " ")
  splits = filter(splits, proc(x: string): bool = x.len > 0)
  enumerateToAst(splits)

proc prettyAST() =
  for x in AST:
    stdout.write join(x, "").replace("\n", "\\n")

proc setPath(file: string) = 
  if "/" in file:
    current_path = "$#/" % [file.rsplit("/",1)[0]]
    echo current_path
proc read(file: string) = 
  setPath(file)
  var code = readFile(file)
  for x in code.split("\n"):
    tokenize(strip(x))
  prettyAST()
  echo AST
  evalAST()

discard """
echo "Evaluting Intersect code..."
echo "---------------------------"
echo "$# system" % USE
echo " "
echo "$# test_module" % UNIT
echo "    $# x = 5" % [ENTRY]
echo "    $# z = 5" % [ENTRY]
echo "    $# x == z $#:" % [IF, DO]
echo "        $# 'The condition is true'" % PUT
echo "    $#" % END
echo "$# $# test_module" % [END, UNIT]
tokenize("$#  system" % USE)
tokenize("$# test_module" % UNIT)
tokenize("$# x = 5" % ENTRY)
tokenize("$# z = 5" % ENTRY)
tokenize("$# x == z $#:" % [IF, DO])
tokenize("$# 'The condition is true'" % PUT)
tokenize(END)
tokenize("$# $# test_module" % [END, UNIT])

echo "---------------------------"
echo "AST Generated"
echo "---------------------------"
echo join(AST, "")
echo AST
echo "---------------------------"
echo "Evaluating AST"
echo "---------------------------"
evalAST()
"""
