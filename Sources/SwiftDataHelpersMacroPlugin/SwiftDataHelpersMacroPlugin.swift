import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftDataHelpersMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CRUDMacro.self,
        RelationshipQueriesMacro.self,
    ]
}
