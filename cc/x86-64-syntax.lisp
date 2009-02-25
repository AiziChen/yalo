;;;; -*- Mode: Lisp -*-
;;;; Author: 
;;;;     Yujian Zhang <yujian.zhang@gmail.com>
;;;; Description:
;;;;     Syntax tables for x86-64.
;;;; License: 
;;;;     GNU General Public License v2
;;;;     http://www.gnu.org/licenses/gpl-2.0.html

(in-package :cc)

(defun arith-syntax-1 (mnemonic 64bit-only?)
  "Return syntax table for arithmetic operations:
adc/add/and/cmp/or/sbb/sub/xor."
  (let ((base   ; Base opcode for operation on r/m8 r8.
         (ecase mnemonic
           (adc #x10) (add #x00) (and #x20) (cmp #x38)
           (or  #x08) (sbb #x18) (sub #x28) (xor #x30)))
        (opcode ; Opcode used when one operand is immediate.
         (ecase mnemonic
           (adc '/2) (add '/0) (and '/4) (cmp '/7)
           (or  '/1) (sbb '/3) (sub '/5) (xor '/6))))
    (if 64bit-only?
        `(;; TODO: For imm8, encode with imm8 with generic r64
          ;; (instead of rax) seems to save 3 bytes.
          ((,mnemonic rax (imm32 imm16 imm8))    . (,(+ base #x05) id))
          ((,mnemonic (r/m64 r64) (imm32 imm16)) . (#x81 ,opcode id))
          ((,mnemonic qword m (imm32 imm16))     . (#x81 ,opcode id))
          ((,mnemonic (r/m64 r64) imm8)          . (#x83 ,opcode ib))
          ((,mnemonic qword m imm8)              . (#x83 ,opcode ib))
          ((,mnemonic (r/m64 r64 m) r64)         . (,(+ base #x01) /r))
          ((,mnemonic r64 (r/m64 r64 m))         . (,(+ base #x03) /r)))
        `(((,mnemonic al imm8)                   . (,(+ base #x04) ib))
          ((,mnemonic ax (imm16 imm8))           . (o16 ,(+ base #x05) iw))
          ((,mnemonic eax (imm32 imm16 imm8))    . (o32 ,(+ base #x05) id))
          ((,mnemonic (r/m8 r8) imm8)            . (#x80 ,opcode ib))
          ((,mnemonic byte m imm8)               . (#x80 ,opcode ib))
          ((,mnemonic (r/m16 r16) imm16)         . (o16 #x81 ,opcode iw))
          ((,mnemonic word m imm16)              . (o16 #x81 ,opcode iw))
          ((,mnemonic (r/m32 r32) (imm32 imm16)) . (o32 #x81 ,opcode id))
          ((,mnemonic dword m (imm32 imm16))     . (o32 #x81 ,opcode id))
          ((,mnemonic (r/m16 r16) imm8)          . (o16 #x83 ,opcode ib))
          ((,mnemonic (r/m32 r32) imm8)          . (o32 #x83 ,opcode ib))
          ((,mnemonic word m imm8)               . (o16 #x83 ,opcode ib))
          ((,mnemonic dword m imm8)              . (o32 #x83 ,opcode ib))
          ((,mnemonic (r/m8 r8 m) r8)            . (,base /r))
          ((,mnemonic (r/m16 r16 m) r16)         . (o16 ,(+ base #x01) /r))
          ((,mnemonic (r/m32 r32 m) r32)         . (o32 ,(+ base #x01) /r))
          ((,mnemonic r8 (r/m8 r8 m))            . (,(+ base #x02) /r))
          ((,mnemonic r16 (r/m16 r16 m))         . (o16 ,(+ base #x03) /r))
          ((,mnemonic r32 (r/m32 r32 m))         . (o32 ,(+ base #x03) /r))))))

(defun arith-syntax-2 (mnemonic)
  "Return syntax table for arithmetic operations: div/mul/neg/not."
  (let ((opcode (ecase mnemonic
                  (div '/6) (mul '/4) (neg '/3) (not '/2))))
    `(((,mnemonic (r/m8 r8))                 . (#xf6 ,opcode))
      ((,mnemonic byte m)                    . (#xf6 ,opcode))
      ((,mnemonic (r/m16 r16))               . (#xf7 ,opcode))
      ((,mnemonic word m)                    . (#xf7 ,opcode)))))

(defun shift-syntax (mnemonic)
  "Return syntax table for shift operations: shl/shr."
  (let ((opcode (ecase mnemonic
                  (shl '/4) (shr '/5))))
    `(((,mnemonic r8 1)                      . (#xd0 ,opcode))
      ((,mnemonic byte m 1)                  . (#xd0 ,opcode))
      ((,mnemonic r8 cl)                     . (#xd2 ,opcode))
      ((,mnemonic byte m cl)                 . (#xd2 ,opcode))
      ((,mnemonic r8 imm8)                   . (#xc0 ,opcode ib))
      ((,mnemonic byte m imm8)               . (#xc0 ,opcode ib))
      ((,mnemonic r16 1)                     . (#xd1 ,opcode))
      ((,mnemonic word m 1)                  . (#xd1 ,opcode))
      ((,mnemonic r16 cl)                    . (#xd3 ,opcode))
      ((,mnemonic word m cl)                 . (#xd3 ,opcode))
      ((,mnemonic r16 imm8)                  . (#xc1 ,opcode ib))
      ((,mnemonic word m imm8)               . (#xc1 ,opcode ib)))))

;;; Following are syntax tables for x86-64. For each entry, 1st part
;;; is the instruction type, 2nd part is the corresponding opcode.
;;; Note that for the 1st part, list may be used for the operand to
;;; match the type (e.g. imm8 converted to imm16). Note that the
;;; canonical form should be placed first (e.g. if the operand type
;;; should be imm16, place it as the car of the list).
;;;
;;;  For details,
;;;    refer to http://code.google.com/p/yalo/wiki/AssemblyX64Overview")

(defparameter *x86-64-syntax-common*
  `(,@(arith-syntax-1 'adc nil)
    ,@(arith-syntax-1 'add nil)
    ,@(arith-syntax-1 'and nil)  
    ((clc)                                   . (#xf8))
    ((cld)                                   . (#xfc))
    ((cli)                                   . (#xfa))
    ((cmovcc r16 (r/m16 r16 m))              . (o16 #x0f (+ #x40 cc) /r))
    ((cmovcc r32 (r/m32 r32 m))              . (o32 #x0f (+ #x40 cc) /r))      
    ,@(arith-syntax-1 'cmp nil)
    ((dec    (r/m8 r8))                      . (#xfe /1))
    ((dec    byte m)                         . (#xfe /1))
    ((dec    (r/m16 r16))                    . (o16 #xff /1))
    ((dec    word m)                         . (o16 #xff /1))
    ((dec    (r/m32 r32))                    . (o32 #xff /1))
    ((dec    dword m)                        . (o32 #xff /1))
    ,@(arith-syntax-2 'div)
    ((hlt)                                   . (#xf4))
    ((in     al imm8)                        . (#xe4 ib)) 
    ((in     ax imm8)                        . (#xe5 ib))
    ((in     al dx)                          . (#xec))
    ((in     ax dx)                          . (#xed))
    ((inc    (r/m8 r8))                      . (#xfe /0))
    ((inc    byte m)                         . (#xfe /0))
    ((inc    (r/m16 r16))                    . (o16 #xff /0))
    ((inc    word m)                         . (o16 #xff /0))
    ((inc    (r/m32 r32))                    . (o32 #xff /0))
    ((inc    dword m)                        . (o32 #xff /0))
    ((int    3)                              . (#xcc))
    ((int    imm8)                           . (#xcd ib))
    ((jcc    short (imm8 label imm16))       . ((+ #x70 cc) rb))
    ((jcc    near (imm32 label imm8 imm16))  . (#x0f (+ #x80 cc) rd))
    ((jmp    short (imm8 label imm16))       . (#xeb rb))
    ((lldt   (r/m16 r16 m))                  . (#x0f #x00 /2))
    ((lodsb)                                 . (#xac))
    ((lodsw)                                 . (#xad))
    ((loop   (imm8 label imm16))             . (#xe2 rb))
    ((mov    r8 imm8)                        . ((+ #xb0 r) ib))
    ((mov    r16 (imm16 imm8 imm label))     . (o16 (+ #xb8 r) iw))
    ((mov    r32 (imm32 imm16 imm8 imm label)) . (o32 (+ #xb8 r) id))
    ((mov    (r/m16 r16 m) r16)              . (o16 #x89 /r))
    ((mov    (r/m32 r32 m) r32)              . (o32 #x89 /r))
    ((mov    r16 (r/m16 r16 m))              . (o16 #x8b /r))
    ((mov    r32 (r/m32 r32 m))              . (o32 #x8b /r))
    ((mov    word m (imm16 imm8 imm label))  . (o16 #xc7 /0 iw))
    ((mov    dword m (imm32 imm16 imm8 imm label)) . (o32 #xc7 /0 id))
    ((mov    sreg (r/m16 r16 m))             . (#x8e /r)) 
    ((mov    (r/m16 r16 m) sreg)             . (#x8c /r)) 
    ((movsb)                                 . (#xa4))
    ((movsw)                                 . (o16 #xa5))
    ((movsd)                                 . (o32 #xa5))
    ,@(arith-syntax-2 'mul)
    ,@(arith-syntax-2 'neg)   
    ((nop)                                   . (#x90))
    ,@(arith-syntax-2 'not)
    ,@(arith-syntax-1 'or nil)
    ((out    imm8 r8)                        . (#xe6 ib))   ; (out imm8 al)
    ((out    imm8 r16)                       . (#xe7 ib))   ; (out imm8 ax)
    ((out    dx al)                          . (#xee))
    ((out    dx ax)                          . (#xef))
    ((pop    r16)                            . ((+ #x58 r)))
    ((push   r16)                            . ((+ #x50 r)))
    ((ret)                                   . (#xc3))
    ,@(shift-syntax 'shl)
    ,@(shift-syntax 'shr)
    ((stc)                                   . (#xf9))
    ((std)                                   . (#xfd))
    ((sti)                                   . (#xfb))
    ((stosb)                                 . (#xaa))
    ((stosw)                                 . (#xab))
    ,@(arith-syntax-1 'sbb nil)
    ,@(arith-syntax-1 'sub nil)
    ((test    al imm8)                       . (#xa8 ib))
    ((test    ax (imm16 imm8))               . (#xa9 iw))
    ((test    (r/m8 r8) imm8)                . (#xf6 /0 ib))
    ((test    byte m imm8)                   . (#xf6 /0 ib))
    ((test    (r/m16 r16 m) (imm16 imm8))    . (#xf7 /0 iw))
    ((test    word m (imm16 imm8))           . (#xf7 /0 iw))
    ((test    (r/m8 r8 m) r8)                . (#x84 /r))
    ((test    (r/m16 r16 m) r16)             . (#x85 /r))
    ,@(arith-syntax-1 'xor nil))
  "Valid for both 16-bit and 64-bit modes.")

(defparameter *x86-64-syntax-16/32-bit-only*
  `(((call   (imm16 imm8 label))             . (#xe8 rw))
    ((dec    r16)                            . (o16 (+ #x48 r)))
    ((dec    r32)                            . (o32 (+ #x48 r)))
    ((inc    r16)                            . (o16 (+ #x40 r)))
    ((inc    r32)                            . (o32 (+ #x40 r)))
    ((lgdt   m)                              . (#x0f #x01 /2))
    ((lidt   m)                              . (#x0f #x01 /3))
    ((pop    ss)                             . (#x17))
    ((pop    ds)                             . (#x1f))
    ((pop    es)                             . (#x07))
    ((push   cs)                             . (#x0e))
    ((push   ss)                             . (#x16))
    ((push   ds)                             . (#x1e))
    ((push   es)                             . (#x06)))
  "Valid for 16-bit mode only.")

(defparameter *x86-64-syntax-64-bit-only*
  `(,@(arith-syntax-1 'adc t)
    ,@(arith-syntax-1 'add t)
    ,@(arith-syntax-1 'and t)
    ((cmovcc r64 (r/m64 r64 m))              . (#x0f (+ #x40 cc) /r))
    ,@(arith-syntax-1 'cmp t)
    ((dec    (r/m64 r64))                    . (#xff /1))
    ((dec    qword m)                        . (#xff /1))
    ((inc    (r/m64 r64))                    . (#xff /0))
    ((inc    qword m)                        . (#xff /0))
    ,@(arith-syntax-1 'or  t)
    ,@(arith-syntax-1 'sbb t)
    ,@(arith-syntax-1 'sub t)
    ((syscall)                               . (#x0f #x05))
    ((sysret)                                . (#x0f #x07))
    ,@(arith-syntax-1 'xor t)))

(defparameter *x86-64-syntax-16/32-bit*
  (append *x86-64-syntax-16/32-bit-only* *x86-64-syntax-common*)
  "Syntax table for 16-bit mode.")

(defparameter *x86-64-syntax-64-bit*
  (append *x86-64-syntax-64-bit-only* *x86-64-syntax-common*)
  "Syntax table for 64-bit mode.")

(defun x86-64-syntax (bits)
  "Returns syntax table according to bit mode (16, 32 or 64)."
  (ecase bits
    ((16 32) *x86-64-syntax-16/32-bit*)
    (64 *x86-64-syntax-64-bit*)))

