/*
1. ��������� ������� ���� ������, ����� ����� ������� �� �������
�������:
* ��� ������� (��������, 2015)
* ����� ������� (��������, 4)
* ������� ���� �� ����� �� ���� �������
* ����� ����� ������ �� �����

������� �������� � ������� Sales.Invoices � ��������� ��������.
*/

--�� ������ �� ����� �������� ������� - ������� �� ExtendedPrice
select year(i.InvoiceDate) as "��� �������", month(i.InvoiceDate) as "����� �������" , avg( il.UnitPrice) as "������� ����", sum(il.UnitPrice*il.Quantity) as "����� �������"
from Sales.Invoices i 
left join Sales.InvoiceLines il on i.InvoiceID=il.InvoiceID
group by year(i.InvoiceDate), month(i.InvoiceDate)
order by year(i.InvoiceDate), month(i.InvoiceDate)

/*
2. ���������� ��� ������, ��� ����� ����� ������ ��������� 10 000

�������:
* ��� ������� (��������, 2015)
* ����� ������� (��������, 4)
* ����� ����� ������

������� �������� � ������� Sales.Invoices � ��������� ��������.
*/

TODO: 
select year(i.InvoiceDate) as "��� �������", month(i.InvoiceDate) as "����� �������" ,  sum(il.UnitPrice*il.Quantity) as "����� �������"
from Sales.Invoices i 
left join Sales.InvoiceLines il on i.InvoiceID=il.InvoiceID
group by year(i.InvoiceDate), month(i.InvoiceDate)
having sum(il.UnitPrice*il.Quantity) >10000   ---����� ������ > 10000
order by year(i.InvoiceDate), month(i.InvoiceDate)



/*
3. ������� ����� ������, ���� ������ �������
� ���������� ���������� �� �������, �� �������,
������� ������� ����� 50 �� � �����.
����������� ������ ���� �� ����,  ������, ������.

�������:
* ��� �������
* ����� �������
* ������������ ������
* ����� ������
* ���� ������ �������
* ���������� ����������

������� �������� � ������� Sales.Invoices � ��������� ��������.
*/

TODO: 

select year(i.InvoiceDate) as "��� �������", month(i.InvoiceDate) as "����� �������", il.Description as "�����",  min(i.InvoiceDate) as "���� ������ �������", sum(il.UnitPrice*il.Quantity) as "����� ������", sum(Quantity) as "���������� ����������"
from Sales.Invoices i 
left join Sales.InvoiceLines il on i.InvoiceID=il.InvoiceID
group by year(i.InvoiceDate), month(i.InvoiceDate),  il.Description
having sum(Quantity)<50
order by year(i.InvoiceDate), month(i.InvoiceDate)

