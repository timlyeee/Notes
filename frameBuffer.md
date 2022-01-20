# EditBox

addButton => ViewGroup

## RelativeLayout

> RelativeLayout 是一个功能非常强大的界面设计实用工具，因为它可以消除嵌套视图组并使布局层次结构保持扁平化，从而提高性能。如果您发现自己使用了多个嵌套的 LinearLayout 组，只需用一个 RelativeLayout 就可以替换它们。

## ViewGroup.LayoutParams

> LayoutParams are used by views to tell **their parents** how they want to be laid out. See ViewGroup Layout Attributes for a list of all child view attributes that this class supports.

告知父节点其相对位置如何排列。
Button应该为右上。

### WRAP_CONTENT

> which means that the view wants to be just big enough to enclose its content (plus padding)

足够大能容纳所有内容。但是这个属性是有针对width和height的。
