
-- 1. Business insight 1:
-- Tổng doanh thu theo tháng (Order, Customer, Revenue, AoV) Aov: tổng doanh thu/ số lượng đơn hàng (count distinct)
select DATEFROMPARTS(year(OrderDate), month(OrderDate), 1) as MonthStart,
	count(distinct SalesOrderID) as Orders,
	count(distinct CustomerID) as Customer,
	sum(SubTotal) as Revenue,
	sum(SubTotal) / count(distinct CustomerID) as AoV
from [Sales].[SalesOrderHeader]
	group by DATEFROMPARTS(year(OrderDate), month(OrderDate), 1)
	order by DATEFROMPARTS(year(OrderDate), month(OrderDate), 1)

-- 2. Business insight 2:
-- Check xem kênh nào đang có doanh thu tốt để ưu tiên nguồn lực đầu tư vào đó