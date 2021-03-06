(* pseudo immediate value *)

type pseudo_imm =
  | Big of Big_int.big_int
  | Int of int
  | DestLabel of Label.label
  | ContractId of Syntax.contract_id (* an immediate value *)

  | StorageContractSwitcherIndex
  (** [StorageContractSwitcherIndex] is the index of the storage that contains the
   * program counter of the contract entry point.  This is unique to bamboo where
   * an account can become different contracts after stages. *)
  | StorageConstructorArgumentsBegin of Syntax.contract_id
  | StorageConstructorArgumentsSize of Syntax.contract_id
  | InitDataSize of Syntax.contract_id
  (** [InitDataSize cid] represents the size of the data sent to create the transaction.
   *  This data contains the initializing code plus runtime code plus the constructor
   *  argument data.  Since the constructor arguments differ from a contract to a contract,
   *  [InitDataSize] requires a contract id.
   *)
  | ContractOffsetInRuntimeCode of Syntax.contract_id (* where in the runtime code does the contract start.  This index should be a JUMPDEST *)
  | CaseOffsetInRuntimeCode of Syntax.contract_id * Syntax.case_header
  | RuntimeCodeOffset
  | RuntimeCodeSize
  | Minus of pseudo_imm * pseudo_imm


val string_of_pseudo_imm : pseudo_imm -> string

type layout_info

val realize_pseudo_imm : layout_info -> pseudo_imm -> Big_int.big_int
