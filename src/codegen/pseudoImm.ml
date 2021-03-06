(* pseudo immediate value *)

type pseudo_imm =
  | Big of Big_int.big_int
  | Int of int
  | DestLabel of Label.label
  | ContractId of Syntax.contract_id (* an immediate value *)

  | StorageContractSwitcherIndex
  | StorageConstructorArgumentsBegin of Syntax.contract_id
  | StorageConstructorArgumentsSize of Syntax.contract_id (* the size is dependent on the contract id *)
  | InitDataSize of Syntax.contract_id
  | ContractOffsetInRuntimeCode of Syntax.contract_id (* where in the runtime code does the contract start.  This index should be a JUMPDEST *)
  | CaseOffsetInRuntimeCode of Syntax.contract_id * Syntax.case_header
  | RuntimeCodeOffset
  | RuntimeCodeSize
  | Minus of pseudo_imm * pseudo_imm

let rec string_of_pseudo_imm (p : pseudo_imm) : string =
  match p with
  | Big b -> "(Big "^(Big_int.string_of_big_int b)^")"
  | Int i -> "(Int "^(string_of_int i)^")"
  | DestLabel _ -> "DestLabel (print label here)"
  | ContractId _ -> "ContractId (print id here)"
  | StorageContractSwitcherIndex -> "StorageContractSwitcherIndex"
  | StorageConstructorArgumentsBegin _ -> "StorageConstructorArgumentBegin (print contract id)"
  | StorageConstructorArgumentsSize _ -> "StorageConstructorArgumentsSize (print contract id)"
  | InitDataSize cid -> "InitDataSize (print contract id here)"
  | ContractOffsetInRuntimeCode _ -> "ContractOffsetInRuntimeCode (print contact id)"
  | CaseOffsetInRuntimeCode (cid, header) -> "CaseOffsetInRuntimeCode (print contract id, case header)"
  | RuntimeCodeOffset -> "RuntimeCodeOffset"
  | RuntimeCodeSize -> "RuntimeCodeSize"
  | Minus (a, b) -> "(- "^(string_of_pseudo_imm a)^" "^(string_of_pseudo_imm b)^")"


type layout_info =
  { (* The initial data is organized like this: *)
    (* |constructor code|runtime code|constructor arguments|  *)
    init_data_size : Syntax.contract_id -> int
  ; constructor_code_size : int
    (* runtime_coode_offset is equal to constructor_code_size *)
  ; runtime_code_size : int
  ; contract_offset_in_runtime_code : Syntax.contract_id -> int

    (* And then, the runtime code is organized like this: *)
    (* |dispatcher that jumps into a contract|runtime code for contract A|runtime code for contract B|runtime code for contract C| *)

    (* And then, the runtime code for a particular contract is organized like this: *)
    (* |dispatcher that jumps into somewhere|runtime code for case f|runtime code for case g| *)

    (* numbers about the storage *)
    (* The storage during the runtime looks like this: *)
    (* |pc of the current contract|pod contract argument0|pod contract argument1| *)
    (* In addition, array elements are placed at the same location as in Solidity *)

  ; storage_contract_switcher_index : int
  ; storage_constructor_arguments_begin : Syntax.contract_id -> int
  ; storage_constructor_arguments_size : Syntax.contract_id -> int
  }

(* Assuming the layout described above, this definition makes sense. *)
let runtime_code_offset (layout : layout_info) :int =
  layout.constructor_code_size

let rec realize_pseudo_imm (layout : layout_info) (p : pseudo_imm) : Big_int.big_int =
  match p with
  | Big b -> b
  | Int i -> Big_int.big_int_of_int i
  | DestLabel l ->
     failwith "realize_pseudo_imm: destlabel"
  | ContractId cid ->
     failwith "realize_pseudo_imm: should be a pc or an id itself or a signature?"
  | StorageContractSwitcherIndex ->
     Big_int.big_int_of_int layout.storage_contract_switcher_index
  | StorageConstructorArgumentsBegin cid ->
     Big_int.big_int_of_int (layout.storage_constructor_arguments_begin cid)
  | StorageConstructorArgumentsSize cid ->
     Big_int.big_int_of_int (layout.storage_constructor_arguments_size cid)
  | InitDataSize cid ->
     Big_int.big_int_of_int (layout.init_data_size cid)
  | RuntimeCodeOffset ->
     Big_int.big_int_of_int (runtime_code_offset layout)
  | RuntimeCodeSize ->
     Big_int.big_int_of_int (layout.runtime_code_size)
  | ContractOffsetInRuntimeCode cid ->
     Big_int.big_int_of_int (layout.contract_offset_in_runtime_code cid)
  | CaseOffsetInRuntimeCode (cid, case_header) ->
     failwith "realize_pseudo_imm caseoffset"
  | Minus (a, b) ->
     Big_int.sub_big_int (realize_pseudo_imm layout a) (realize_pseudo_imm layout b)
