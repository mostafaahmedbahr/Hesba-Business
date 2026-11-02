p='E:/projects/Hesba-Business/lib/features/expenses/presentation/views/add_expense_view.dart'
s=open(p,encoding='utf-8').read()
old="""                                           ? 'العنوان مطلوب'
                                           : null,
                                     ),
                                   ],
                                 ),"""
new="""                                           ? 'العنوان مطلوب'
                                           : null,
                                     ),
                                     SizedBox(height: 12.h),
                                     _Field(
                                       controller: _shopNameController,
                                       label: 'اسم المحل',
                                       hint: 'اسم المحل (اختياري)',
                                       icon: Icons.storefront_rounded,
                                       isDark: isDark,
                                       onChanged: () => setState(() {}),
                                     ),
                                   ],
                                 ),"""
assert old in s, 'old not found'
s=s.replace(old,new,1)
open(p,'w',encoding='utf-8').write(s)
print('done')