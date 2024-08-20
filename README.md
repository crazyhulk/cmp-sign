# cmp-sign

Get the sign of the function, for example:

input:
`sort.Slice.sign`

output:
`func (x any, less func(i int, j int) bool)`


Support [mockey](https://github.com/bytedance/mockey), which is useful when making a test for ur code. 

![mockey](./mockey.jpg)

You can custom completion menu:

The key will display on the completion menu.
*{{name}}* will be replace by function name, and *{{sign}}* will replace by function sign.

```
require('cmp_sign').setup({
	good = "xxx{{name}}xxxx{{sign}}",
})
```

# install

## Packer
```
use { 'crazyhulk/cmp-sign' }
```

# Setup

```

require'cmp'.setup {
  sources = {
    { name = 'nvim_cmp_sign' }
  }
}
```
