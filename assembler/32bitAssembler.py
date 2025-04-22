import re
import sys

# 4-bit register encoding: R0-R15
REGISTERS = {f'R{i}': i for i in range(16)}

# 2-bit Addressing Mode (AM)
ADDRESS_MODES = {
    'inherent':  0b00,
    'immediate': 0b01,
    'direct':    0b10,
    'register':  0b11
}

# 6-bit OPCODES 
OPCODES = {
    'LDR':      0b000000,
    'STR':      0b000010,
    'JMP':      0b011000,
    'PRESENT':  0b011100,
    'AND':      0b001000,
    'OR':       0b001100,
    'ADD':      0b111000,
    'SUB':      0b000100,
    'SUBV':     0b000011,
    'CLFZ':     0b010000,
    'CER':      0b111100,
    'CEOT':     0b111110,
    'SEOT':     0b111111,
    'NOOP':     0b110100,
    'SZ':       0b010100,
    'LER':      0b110110,
    'SSVOP':    0b111011,
    'SSOP':     0b111010,
    'LSIP':     0b110111,
    'DATACALL': 0b101000,
    'DATACALL2':0b101001,
    'MAX':      0b011110,
    'STRPC':    0b011101,
    'SRES':     0b101010,
}

def parse_operand(op, labels):
    op = op.strip()
    if op.startswith('#'):
        remainder = op[1:]
        if remainder in labels:
            return ADDRESS_MODES['immediate'], labels[remainder]
        else:
            return ADDRESS_MODES['immediate'], int(remainder, 0)
    elif op.startswith('$'):
        remainder = op[1:]
        if remainder in labels:
            return ADDRESS_MODES['direct'], labels[remainder]
        else:
            return ADDRESS_MODES['direct'], int(remainder, 0)
    elif op in REGISTERS:
        return ADDRESS_MODES['register'], REGISTERS[op]
    elif op in labels:
        return ADDRESS_MODES['direct'], labels[op]
    else:
        return ADDRESS_MODES['inherent'], 0


def collect_labels(lines):
    labels = {}
    pc = 0
    for line in lines:
        line = line.strip()
        if not line or line.startswith(';'):
            continue
        if ':' in line:
            parts = line.split(':', 1)
            label = parts[0].strip()
            labels[label] = pc
            if parts[1].strip() != "":
                pc += 1
        else:
            pc += 1
    return labels

def assemble_line(line, labels):
    # Hilangkan komentar dan label
    if ';' in line:
        line = line.split(';')[0]
    line = line.strip()
    if not line:
        return None
    if ':' in line:
        line = line.split(':', 1)[1].strip()
    if not line:
        return None

    tokens = re.split(r'[,\s]+', line)
    if not tokens:
        return None

    mnemonic = tokens[0].upper()
    operands = tokens[1:]
    
    if mnemonic in ("LDR", "STR") and len(operands) > 2:
        raise ValueError(f"{mnemonic} instruction takes maximum 2 operands, got {len(operands)}")
    
    if mnemonic not in OPCODES:
        raise ValueError(f"Unknown instruction: {mnemonic}")
    opcode = OPCODES[mnemonic]
    am = ADDRESS_MODES['inherent']
    rz = rx = imm = 0

    if len(operands) == 3:
        if operands[2].startswith('#'):
            am = ADDRESS_MODES['immediate']
            _, rz = parse_operand(operands[0], labels)
            _, rx = parse_operand(operands[1], labels)
            _, imm = parse_operand(operands[2], labels)
        else:
            am = ADDRESS_MODES['register']
            _, rz = parse_operand(operands[0], labels)
            _, rx = parse_operand(operands[2], labels)
            imm = 0 
        instr = ((am << 30) | (opcode << 24) | (rz << 20) | (rx << 16) | (imm & 0xFFFF)) & 0xFFFFFFFF
    elif len(operands) == 2:
        if mnemonic == "STR" and operands[1].startswith('$'):
            am = ADDRESS_MODES['direct']
            _, rx = parse_operand(operands[0], labels)  # Use the first operand as Rx
            _, imm = parse_operand(operands[1], labels)
            instr = ((am << 30) | (opcode << 24) | (0 << 20) | (rx << 16) | (imm & 0xFFFF)) & 0xFFFFFFFF
        elif operands[0] in REGISTERS and operands[1] in REGISTERS:
            am = ADDRESS_MODES['register']
            _, rz = parse_operand(operands[0], labels)
            _, rx = parse_operand(operands[1], labels)
            instr = ((am << 30) | (opcode << 24) | (rz << 20) | (rx << 16)) & 0xFFFFFFFF
        else:
            if mnemonic == "PRESENT" or operands[1].startswith('#'):
                am = ADDRESS_MODES['immediate']
            else:
                am = ADDRESS_MODES['direct']
            _, rz = parse_operand(operands[0], labels)
            _, imm = parse_operand(operands[1], labels)
            instr = ((am << 30) | (opcode << 24) | (rz << 20) | (imm & 0xFFFF)) & 0xFFFFFFFF
    elif len(operands) == 1:
        # For instructions that use the operand as Rx rather than Rz:
        if mnemonic in ("JMP", "DATACALL", "SSOP"):
            if operands[0] in REGISTERS:
                am = ADDRESS_MODES['register']
                _, rx = parse_operand(operands[0], labels)
                instr = ((am << 30) | (opcode << 24) | (rx << 16)) & 0xFFFFFFFF
            else:
                am = ADDRESS_MODES['immediate']
                _, imm = parse_operand(operands[0], labels)
                instr = ((am << 30) | (opcode << 24) | (imm & 0xFFFFFF)) & 0xFFFFFFFF
        else:
            # Default: treat operand as Rz
            am = ADDRESS_MODES['register']
            _, value = parse_operand(operands[0], labels)
            instr = ((am << 30) | (opcode << 24) | (value << 20)) & 0xFFFFFFFF
    else:
        instr = ((am << 30) | (opcode << 24)) & 0xFFFFFFFF
    return f"{instr:08X}"

def assemble_file(filename):
    with open(filename, encoding='utf-8') as f:
        lines = f.readlines()
    labels = collect_labels(lines)
    output = []
    for line in lines:
        try:
            encoded = assemble_line(line, labels)
            if encoded:
                output.append(encoded)
        except Exception as e:
            print(f"Error: {e} in line: {line.strip()}")
    return output

def save_output(filename, hex_lines):
    with open(filename, "w") as f:
        for h in hex_lines:
            f.write(h + '\n')
    print(f"✅ Assembly complete. Output written to: {filename}")

def save_output_as_mif(filename, hex_lines):
    with open(filename, "w") as f:
        f.write("WIDTH=32;\n")
        f.write("DEPTH=32768;\n\n")
        f.write("ADDRESS_RADIX=HEX;\n")
        f.write("DATA_RADIX=HEX;\n\n")
        f.write("CONTENT BEGIN\n")
        for i in range(32768):
            if i < len(hex_lines):
                f.write(f"    {i:04X} : {hex_lines[i]};\n")
            else:
                f.write(f"    {i:04X} : 00000000;\n")
        f.write("END;\n")
    print(f"✅ Assembly complete. Output written to: {filename}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python assembler32bit.py yourprogram.asm")
        sys.exit(1)
    asmfile = sys.argv[1]
    hex_lines = assemble_file(asmfile)
    save_output_as_mif("output.mif", hex_lines)
