#!/usr/bin/python3
#%%

m = 1

doc = f'''
let f(x,y) = x .*. y
let g(x) = x .*. 2
let h(x) = x .*. 7
let F(x) = f(g(h(x)),h(g(x)))
let t0(x) = F x
'''

for x in range(0,m):
    doc = doc + f"\nlet t{x+1}(x) = F(t{x}(x))"

doc = doc + f'\nprint "t" t{m}(0)'

print(doc)


# %%
