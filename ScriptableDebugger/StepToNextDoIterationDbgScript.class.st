"
If aContext has among its senders a context for the #do: method of an instance of Collection (or subclasses), step until the next time the argument block of #do: is executed (or until the #do: context is popped if it happens first)
"
Class {
	#name : #StepToNextDoIterationDbgScript,
	#superclass : #DebuggerScript,
	#instVars : [
		'startContext',
		'scdbg',
		'doContext',
		'doArgumentBlock'
	],
	#category : #ScriptableDebugger
}

{ #category : #example }
StepToNextDoIterationDbgScript class >> doCollectionExample [
	|a|
	a := OrderedCollection new.
	{ 1 . 2 . 3 } do: [ :int | a add: int. a add: int ].
]

{ #category : #example }
StepToNextDoIterationDbgScript class >> runExample [
	<script>
	| scdbg |
	scdbg := ScriptableDebugger2 debug: [ self doCollectionExample ].
	self halt.
	"Execute the following to open the execution in a graphical debugger."
	"scdbg openInGraphicalDebugger."
	"Gets inside the #do: context"
	scdbg step; stepOver; step; step; step.
	scdbg refreshAttachedGraphicalDebugger.
	
	"Gets inside the first activation of the block given as argument to the #do: message. (int = 1)"
	scdbg executeDebuggerScriptNamed: #StepToNextDoIteration.
	scdbg refreshAttachedGraphicalDebugger.
	
	"Step a little in this block's execution, to change context"
	scdbg step; step.
	scdbg refreshAttachedGraphicalDebugger.
	
	"Finishes the block's execution, steps until the #do: context is reached, then step to the secon activation of the block given as argument to the #do: message. (int = )"
	scdbg executeDebuggerScriptNamed: #StepToNextDoIteration.
	scdbg refreshAttachedGraphicalDebugger.
	
	"Step to the third an final iteration of the #do:"
	scdbg executeDebuggerScriptNamed: #StepToNextDoIteration.
	scdbg refreshAttachedGraphicalDebugger.
	
	"Finishes the third iteration. Steps to find the next one, but since there isn't any, steps until the #do: context is no longer on the stack"
	scdbg executeDebuggerScriptNamed: #StepToNextDoIteration.
	scdbg refreshAttachedGraphicalDebugger.
	
	"Does nothing because no #do: context is found on the stack"
	scdbg executeDebuggerScriptNamed: #StepToNextDoIteration.
	scdbg refreshAttachedGraphicalDebugger.
]

{ #category : #accessing }
StepToNextDoIterationDbgScript class >> scriptName [
	^ 'StepToNextDoIteration'
]

{ #category : #running }
StepToNextDoIterationDbgScript >> execute: aScriptableDebugger [
	| stepHook |
	scdbg := aScriptableDebugger.
	startContext := aScriptableDebugger currentContext.
	"doContext is the context for the #do: message send to an instance of Collection (or subclass)"
	doContext := scdbg findContextForSelector: #do: andClassOrSubclassOf: Collection.
	doContext ifNil: [ ^false ].
	"doArgumentBlock is the block that has been given to the #do: message as argument. It is the block to be executed on each element of the collection"
	doArgumentBlock := doContext arguments at: 1.
	"Add a step hook that will raise a ContextNotOnStack exception if at any point, the doContext is no longer on the stack (this can happens when exceptions are involved)"
	stepHook := [ (scdbg contextIsOnStack: doContext) ifFalse: [ ContextNotOnStack signal ] ].
	scdbg addStepHook: stepHook.
	[
		"case 1: startContext is above or equal to a block context for the do:'s block"
		(scdbg findContextSuchThat: [:ctxt | scdbg context: ctxt isForBlock: doArgumentBlock]) ifNotNil: [ 
			scdbg stepToContext: doContext.
			scdbg stepToContextForBlock: doArgumentBlock.
			scdbg removeStepHook: stepHook.
			^true. 
		].
		"case 2: startContext is above the doContext and there is no block context for doArgumentBlock between them"
		scdbg stepToContextForBlock: doArgumentBlock.
		scdbg removeStepHook: stepHook.
		^ true.
	] on: ContextNotOnStack do: [
		scdbg removeStepHook: stepHook.
		^ self
	].
]