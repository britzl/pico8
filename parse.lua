local cart = [[t={}w=128 m=432 l=200 p=w/2
for i=0,m/6-1 do
	add(t,{i*6,8+i%6})
end
::_::cls(1)
for i=#t,1,-1 do
	o=t[i]a=o[1]/m
	line(-16,p,l*cos(a),p-l*sin(a),o[2])
	line(w+15,p,w-l*cos(a),p-l*sin(a),o[2])
	fooo+=1 fooo+=1
	booo[foo[1] ]+=1
end
flip()goto _]]


local parsed = string.gsub(cart, "([%a_][%a%d_]-)(%b[])([%+%-])=", "%1%2=%1%2%3")
parsed = string.gsub(parsed, "([%a_][%a%d_]-)([%+%-])=", "%1=%1%2")
print(parsed)



--local cart_fn = assert(loadstring(cart))
