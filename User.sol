pragma solidity ^0.4.24;

import "./Table.sol";

//import "github.com/Arachnid/solidity-stringutils/strings.sol";

//使用方法
//function foo(string s1, string s2) {
//      s = s1.toSlice().concat(s2.toSlice());
//  }

contract User {
    //User智能合约用来进行上架下架等操作。
    // event
	event Create_commodity(int256 ret, string user , int256 commodity_id);
    event Puton_commodity(int256 ret, string user, int256 commodity_id);
    event Putdown_commodity(int256 ret, string user, int256 commodity_id);
	event Delete_commodity(int256 ret, string user, int256 commodity_id);
    event Buy_commodity(int256 ret,string user_sell, string user_buy, int256 commodity_id);
	event TransferEvent(int256 ret, string from_account, string to_account, uint256 amount);
	event Create_transaction(int256 ret, int256 id);
	event Initiate_arbitration(int256 ret,string user , int256 id);


	
    constructor() public {
        // 构造函数中创建t_task4表
        //createTable();
	open_commodity_table();
    }
	
	
	
	
	
	//打开用户表
    function open_user_table() private returns(Table) {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("t_user");
        return table;
    }
	//打开仲裁表
	function open_transaction_table() private returns(Table) {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("t_transaction");
        return table;
    }
	//打开商品表
	function open_commodity_table() private returns(Table) {
        TableFactory tf = TableFactory(0x1001);
        Table table = tf.openTable("t_commodity");
        return table;
    }
	
	
	//用来确定commodity_id该id即是商品的个数
	  function set_commodity_id() public constant returns(int256) {
        // 打开表
        Table table = open_commodity_table();
        // 查询选取主键
        Entries entries = table.select("key", table.newCondition());		
		return int256(entries.size())+1;
    }

	
	//用来判断商品状态
	function get_commodity_state(int256 id) public constant returns(int256,int256){
	Table table_commodity=open_commodity_table();
	
	Condition condition=table_commodity.newCondition();
	condition.EQ("rid",id);
	Entries entries = table_commodity.select("key",condition);
	// 猜测是按顺序排序的
	Entry entry=entries.get(0);
	

	//先试试getBytes32 能不能用
	//commodity_info temp_info=commodity_info(entry.getBytes32("info"));
	//或者直接使用rid
	int256 temp_state=int256(entry.getInt("state"));

	return(int256(entry.getInt("rid")),temp_state);
	}
	
	
	
	
	//选取商品
	function select_commodity(int256 id) public returns(Entry){
	
		Table table_commodity=open_commodity_table();
		Condition condition=table_commodity.newCondition();
	condition.EQ("rid",id);
	Entries entries = table_commodity.select("key",condition);
	// 猜测是按顺序排序的
	
	if(entries.size()==0)
	{
		Entry entry=table_commodity.newEntry();
		entry.set("id","NULL");
		entry.set("name","NULL");
		entry.set("price",int256(-999));
		entry.set("picture","NULL");
		entry.set("descr","NULL");
		entry.set("state",int256(-999));
		entry.set("owner","NULL");
		entry.set("rid",int256(-999));
		entry.set("commodity_type",int256(-999));
		return entry;
	
	}
	Entry entry0=entries.get(0);
	return entry0;
	}

	
	//用来判断用户是否登陆 0注销 1在线 -1用户不存在 
	//只有状态为1的时候是可用的
	function get_user_state(string user) public constant returns(int256)
	{
		Table table=open_user_table();
		Entries entries = table.select(user,table.newCondition());
		if(0==uint256(entries.size())){
		//用户不存在
		return -1;
		}else{
		Entry entry = entries.get(0);

		return int256(entry.getInt("state"));
		}
	}
	
	//返回1成功创建商品
	//-1用户状态不对
	//-2其他问题
	function create_commodity(string user , string name, string picture,string descr) public returns(int256){
			int256 state=get_user_state(user);
		   int256 ret=0;
		   
		   if(state!=1){
			ret=-1;
			emit Create_commodity( ret, user, id);
		       return -1;
			}
			int256 id=set_commodity_id();
			//商品状态
			//state 1为上架，0为下架,-1为删除
			int256 commodity_state=0;
		  Table table_commodity=open_commodity_table();
		  Entry entry=table_commodity.newEntry();
		  entry.set("id","key");
		  entry.set("name",string(name));
		  entry.set("price",int256(0));
		  entry.set("picture",string(picture));
		  entry.set("descr",string(descr));
		  entry.set("state",int256(commodity_state));
		  entry.set("owner",string(user));
		  entry.set("rid",id);
		  entry.set("commodity_type",int256(-1));//-1表示没有设置分类
		  int count = table_commodity.insert("key", entry);
		   if (count == 1) {
                // 成功
                ret = 1;
				emit Create_commodity( ret, user, id);
				return ret;
            } else {
                // 失败? 无权限或者其他错误
                ret = -2;
				emit Create_commodity( ret, user, id);
				return ret;
            }
		 return -2;

		  }// 上架操作结束
		  
		 
		 
		 
		 
	//获取商品信息
	function get_commodity_info(int256 id) public  returns(string,string,string,string,int256,int256,int256,int256)
	{
		
	   Entry entry=select_commodity(id);
 return(string(entry.getString("owner")),string(entry.getString("name")),string(entry.getString("picture")),string(entry.getString("descr")),int256(entry.getInt("price"))
	   ,int256(entry.getInt("state")),int256(entry.getInt("rid")),int256(entry.getInt("commodity_type")));

	//如果不能得到返回值的话就用下面的代码,把返回类型改成returns(string,string,string,string,int256[])
	//int256[] memory commodity_list=new int256[](uint256(3));
	//commodity_list[uing256(0)]=int256(entry.getInt("price"),
	//commodity_list[uint256(1)]=int256(entry.getInt("state"),
	//commodity_list[uint256(2)]=int256(entry.getInt("rid"),
	//return (string(entry.getString("owner")),string(entry.getString("name")),string(entry.getString
        //("picture")),string(entry.getString("descr")),commodity_list);
	

	}
	
	
	
	
	//获取用户信息
	function get_user_info(string id) public  returns(string,string,uint256,int256)
	{

	   Table table=open_user_table();
	   Entries entries=table.select(id,table.newCondition());
	   if(entries.size()==0)
	   {
		return ("NULL","NULL",0,-999);
	   }
	   Entry entry=entries.get(0);
	
	   return(string(entry.getString("id")),string(entry.getString("info")),uint256(entry.getUInt("balance")),int256(entry.getInt("state")));
	}
	
	//获取交易信息
	function get_transaction_info(int256 rid) public returns(string,string,string,string,int256,int256,int256)
	{
		
		Table table=open_transaction_table();
		Condition condition=table.newCondition();
		condition.EQ("rid",rid);
		Entries entries=table.select("key",condition);
		if(entries.size()==0)
		{
			return ("NULL","NULL","NULL","NULL",-999,-999,-999);
		}
		
		Entry entry=entries.get(0);
		//"user_sell,user_buy,commodity_id,price,descr,rid,state"
		return (entry.getString("transaction_reason"),entry.getString("user_sell"),entry.getString("user_buy"),entry.getString("descr"),entry.getInt("commodity_id"),entry.getInt("price"),entry.getInt("state"));
	
	
	}
	
	
	
	
	
	
	
	//获取出售商品列表
	 function get_onsale_list() returns(int256[],int256){
	Table table_commodity=open_commodity_table();
	Condition condition=table_commodity.newCondition();
	condition.EQ("state",int256(1));
	Entries entries=table_commodity.select("key",condition);
	int256 i=0;

       int256[] memory commodity_list=new int256[](uint256(entries.size()));
	for(i;i<entries.size();i++)
	{
		Entry entry=entries.get(i);
		commodity_list[uint256(i)]=int256(entry.getInt("rid"));
	}
	
	//delete commodity_list;
	return (commodity_list,entries.size());
	
	}
	
	//获取特定的类型的商品
	function get_onsale_type_list(int256 commodity_type)returns(int256[],int256){
	Table table_commodity=open_commodity_table();
	Condition condition=table_commodity.newCondition();
	condition.EQ("state",int256(1));
	condition.EQ("commodity_type",commodity_type);
	Entries entries=table_commodity.select("key",condition);
	int256 i=0;

       int256[] memory commodity_list=new int256[](uint256(entries.size()));
	for(i;i<entries.size();i++)
	{
		Entry entry=entries.get(i);
		commodity_list[uint256(i)]=int256(entry.getInt("rid"));
	}
	
	//delete commodity_list;
	return (commodity_list,entries.size());
	
	}
	

	//获取用户的商品list，列表返回id序列
	function get_commodity_list(string user) returns(int256[],int256){
	Table table_commodity=open_commodity_table();
	Condition condition=table_commodity.newCondition();
	condition.EQ("owner",user);
	Entries entries=table_commodity.select("key",condition);
	int256 i=0;

       int256[] memory commodity_list=new int256[](uint256(entries.size()));
	for(i;i<entries.size();i++)
	{
		Entry entry=entries.get(i);
		commodity_list[uint256(i)]=int256(entry.getInt("rid"));
	}
	
	//delete commodity_list;
	return (commodity_list,entries.size());
	
	}
	//获取需要仲裁的交易列表
	function get_arbitration_list() public returns(int256 [],int256)
	{
		Table table_transaction=open_transaction_table();
	Condition condition=table_transaction.newCondition();
	condition.EQ("state",int256(0));
	Entries entries=table_transaction.select("key",condition);
	
	
	int256 i=0;

       int256[] memory commodity_list=new int256[](uint256(entries.size()));
	for(i;i<entries.size();i++)
	{
		Entry entry=entries.get(i);
		commodity_list[uint256(i)]=int256(entry.getInt("rid"));
	}
	
	//delete commodity_list;
	return (commodity_list,entries.size());	
	}
	
	//获取仲裁信息
	function get_arbitration_reason(int256 id) public returns(string)
	{
		Table table_transaction=open_transaction_table();
		Condition condition=table_transaction.newCondition();
		condition.EQ("rid",id);
		condition.EQ("state",0);
		Entries entries=table_transaction.select("key",condition);
		if(entries.size()==0)
		{
			string memory re="NULL";
			return re;
		}
		Entry entry=entries.get(0);
		
		return entry.getString("transaction_reason");	
	}
	
	
	//获取购买的交易记录，返回值是交易项和交易项的大小，列表返回id序列
	function get_transaction_buy_list(string user) returns(int256[],int256){
	Table table_transaction=open_transaction_table();
	Condition condition=table_transaction.newCondition();
	condition.EQ("user_buy",user);
	Entries entries=table_transaction.select("key",condition);
	
	
	int256 i=0;

       int256[] memory commodity_list=new int256[](uint256(entries.size()));
	for(i;i<entries.size();i++)
	{
		Entry entry=entries.get(i);
		commodity_list[uint256(i)]=int256(entry.getInt("rid"));
	}
	
	//delete commodity_list;
	return (commodity_list,entries.size());
	}
	
	//获取出售的交易记录,返回值是交易项和交易项的大小，列表返回id序列
	function get_transaction_sell_list(string user) returns(int256[],int256){
	Table table_transaction=open_transaction_table();
	Condition condition=table_transaction.newCondition();
	condition.EQ("user_sell",user);
	Entries entries=table_transaction.select("key",condition);
	
	
	int256 i=0;

       int256[] memory commodity_list=new int256[](uint256(entries.size()));
	for(i;i<entries.size();i++)
	{
		Entry entry=entries.get(i);
		commodity_list[uint256(i)]=int256(entry.getInt("rid"));
	}
	
	//delete commodity_list;
	return (commodity_list,entries.size());
	}
	
	
	
	//返回-1用户问题
	//1成功
	//-2其他问题
	function puton_commodity(string user , int256 id,int256 price,int256 commodity_type) public returns(int256){
	       int256 state=get_user_state(user);
		   int256 ret=0;
		   
		   if(state!=1){
		     return -1;
		  }else{
		  
		  Table table_commodity=open_commodity_table();
		  Condition condition=table_commodity.newCondition();
		  condition.EQ("rid",id);
		  Entries entries=table_commodity.select("key",condition);
		  //可能会出现entry不符合格式的问题
		  Entry entry=entries.get(0);
		  //商品已经是上架状态
		  if(int256(entry.getInt("state"))==1)
		  {
			return -2;
		  }
		  entry.set("state",int256(1));
		  entry.set("price",price);
		  entry.set("commodity_type",commodity_type);
		  int256 count=table_commodity.update("key",entry,condition);
		   if (count == 1) {
                // 成功
                ret = 1;
				emit Puton_commodity( ret, user,id);
				return ret;
            } else {
                // 失败? 无权限或者其他错误
                ret = -2;
				emit Puton_commodity( ret, user,id);
				return ret;
            }

		  }// 上架操作结束
		  
		  return -2;
	}
	
	//返回-1用户问题
	//1成功
	//-2其他问题
	
	function delete_commodity(string user,int256 id) public returns(int256){
		int256 state=get_user_state(user);
		   int256 ret=0;
		   
		   if(state!=1){
		     return -1;
		  }else{
		  
		  Table table_commodity=open_commodity_table();
		  Condition condition=table_commodity.newCondition();
		  condition.EQ("rid",id);
		  Entries entries=table_commodity.select("key",condition);
		  //可能会出现entry不符合格式的问题
		  Entry entry=entries.get(0);
		  //商品已经是删除状态
		  if(int256(entry.getInt("state"))==-1)
		  {
			return -2;
		  }
		  entry.set("state",-1);
		  int256 count=table_commodity.update("key",entry,condition);
		   if (count == 1) {
                // 成功
                ret = 1;
				emit Delete_commodity( ret, user,id);
				return ret;
            } else {
                // 失败? 无权限或者其他错误
                ret = -2;
				return ret;
            }

		  }// 上架操作结束
		  
		  return -2;
		}
		
	//返回-1用户问题
	//1成功
	//-2其他问题
	
	function putdown_commodity(string user,int256 id ) public returns(int256){
		int256 state=get_user_state(user);
		   int256 ret=0;
		   
		   if(state!=1){
		     return -1;
		  }else{
		  
		  Table table_commodity=open_commodity_table();
		  Condition condition=table_commodity.newCondition();
		  condition.EQ("rid",id);
		  Entries entries=table_commodity.select("key",condition);
		  Entry entry=entries.get(0);
		  //商品已经是下架状态
		  if(int256(entry.getInt("state"))==0)
		  {
			return -2;
		  }
		  entry.set("state",int256(0));
		  int256 count=table_commodity.update("key",entry,condition);
		   if (count == 1) {
                // 成功
                ret = 1;
				emit Putdown_commodity( ret, user,id);
				return ret;
            } else {
                // 失败? 无权限或者其他错误
                ret = -2;
				return ret;
            }

		  }// 上架操作结束
		  
		  return -2;
		}
		
		
		//打开用户表并选择用户
		 function select(string account) public constant returns(int256, uint256,int256) {
        // 打开表
        Table table = open_user_table();
        // 查询
        Entries entries = table.select(account, table.newCondition());
        uint256 asset_value = 0;
        if (0 == uint256(entries.size())) {
            return (-1, asset_value,4);
        } else {
            Entry entry = entries.get(0);
            return (0, uint256(entry.getInt("balance")),int256(entry.getInt("state")));
        }
			}
		
		
		
		/*
    描述 : 资产转移
    参数 ：
            from_account : 转移资产账户
            to_account ： 接收资产账户
            amount ： 转移金额
    返回值：
            0  资产转移成功
            -1 转移资产账户不存在
            -2 接收资产账户不存在
            -3 金额不足
            -4 金额溢出
            -5 其他错误
			-6 账户状态问题
    */
    function transfer(string from_account, string to_account, uint256 amount) public returns(int256) {
        // 查询转移资产账户信息
        int ret_code = 0;
        int256 ret = 0;
        uint256 from_asset_value = 0;
        uint256 to_asset_value = 0;
	int256 from_state=0;
	int256 to_state=0;
        // 转移账户是否存在?
        (ret, from_asset_value,from_state) = select(from_account);
        if(ret != 0) {
            ret_code = -1;
            // 转移账户不存在
            emit TransferEvent(ret_code, from_account, to_account, amount);
            return ret_code;

        }
		
        // 接受账户是否存在?
        (ret, to_asset_value,to_state) = select(to_account);
        if(ret != 0) {
            ret_code = -2;
            // 接收资产的账户不存在
            emit TransferEvent(ret_code, from_account, to_account, amount);
            return ret_code;
        }

        if(from_asset_value < amount) {
            ret_code = -3;
            // 转移资产的账户金额不足
            emit TransferEvent(ret_code, from_account, to_account, amount);
            return ret_code;
        }

        if (to_asset_value + amount < to_asset_value) {
            ret_code = -4;
            // 接收账户金额溢出
            emit TransferEvent(ret_code, from_account, to_account, amount);
            return ret_code;
        }

        Table table = open_user_table();
        Entry entry0 = table.newEntry();
        entry0.set("id", from_account);
        entry0.set("balance", int256(from_asset_value - amount));
        // 更新转账账户
        int count = table.update(from_account, entry0, table.newCondition());
        if(count != 1) {
            ret_code = -5;
            // 失败? 无权限或者其他错误?
            emit TransferEvent(ret_code, from_account, to_account, amount);
            return ret_code;
        }

        Entry entry1 = table.newEntry();
        entry1.set("id", to_account);
        entry1.set("balance", int256(to_asset_value + amount));
        // 更新接收账户
        table.update(to_account, entry1, table.newCondition());
	  emit TransferEvent(ret_code, from_account, to_account, amount);
        return ret_code;
    }
		
		
		
		
		
		
		
		//创建交易记录
		//返回1表示成功
		function create_transaction(string us , string ub, int256 commodity_id, int256 price,string descr ) public returns(int256)
		{
			Table table_transaction=open_transaction_table();
			Entries entries = table_transaction.select("key", table_transaction.newCondition());		
			Entry entry=table_transaction.newEntry();
			int256 id=int256(entries.size()+1);
			entry.set("id","key");
			entry.set("rid",int256(id));
			entry.set("user_sell",string(us));
			entry.set("user_buy",string(ub));
			entry.set("commodity_id",int256(commodity_id));
			entry.set("descr",string(descr));
			entry.set("price",int256(price));
			entry.set("transaction_reason","NULL");
			//State表示当前交易的状态
			//state=0表示发起仲裁
			//state=1表示完成交易
			entry.set("state",int256(1));
			int256 count=table_transaction.insert("key",entry);
			emit Create_transaction(count,id);
			
			return count;
		}
		
		
		
		//购买商品
		//0成功
		//-1用户验证失败
		//-2商品状态不对
		//-3转账问题
		//-4 修改拥有者信息
		//-5交易记录生成出错
		function buy_commodity(string user_buy, int256 commodity_id,string descr) public returns(int256){
		int256 user_buy_state=get_user_state(user_buy);
		if(user_buy_state!=1)
		{
			emit Buy_commodity(-1,"NULL", user_buy, commodity_id);
			return -1;
		}
		
		
			Entry entry =select_commodity(commodity_id);
			//commodity_info info=commodity_info(entry.getBytes32("info"));
			if(int256(entry.getInt("state"))!=1)
			{
				emit Buy_commodity(-2,"NULL", user_buy, commodity_id);
				return -2;
			}
			string memory user_sell=entry.getString("owner");
			
			int256 result=transfer(user_buy,user_sell,uint256(entry.getInt("price")));
			
			if(result!=0)
			{
				emit Buy_commodity(-3,user_sell, user_buy, commodity_id);
				return -3;
			}
			Table table_commodity=open_commodity_table();
			Entry entry0=table_commodity.newEntry();
			entry0.set("owner",user_buy);
			entry0.set("state",int256(0));
			Condition condition = table_commodity.newCondition();
			condition.EQ("rid", commodity_id);
			
			result=table_commodity.update("key",entry0,condition);
			if(result!=1)
			{
				emit Buy_commodity(-4,user_sell, user_buy, commodity_id);
				return -4;
			}
			
			result=create_transaction(user_sell,user_buy,commodity_id,entry.getInt("price"),descr);
			if(result!=1)
			{
				emit Buy_commodity(-5,user_sell, user_buy, commodity_id);
				return -5;
			}
			emit Buy_commodity(0,user_sell, user_buy, commodity_id);
			return 0;
			
		}
		
		//发起仲裁
		//0成功发起仲裁
		//-1用户状态不对
		//-2不存在对应交易记录
		//-3状态修改失败
		//-4超出仲裁时间
		//-5用户没有权限
		function initiate_arbitration(string user ,int256 t_id,string transaction_reason) public returns(int256){
		
		int256 user_state=get_user_state(user);
		if(user_state!=1)
		{
		    emit  Initiate_arbitration(-1,user,t_id);
			return -1;
		}
		Table table_transaction=open_transaction_table();
		Condition condition=table_transaction.newCondition();
		condition.EQ("rid",t_id);
		Entries entries=table_transaction.select("key",condition);
		if(entries.size()==0)
		{
			emit  Initiate_arbitration(-2,user,t_id);
			return -2;
		
		}
		Entry entry=entries.get(0);
		//transaction_info info=transaction_info(entry.getBytes32("info"));
		//info.date2=date;
		
		
		if(keccak256(entry.getString("user_sell"))!=keccak256(user))
		{
			if(keccak256(entry.getString("user_buy"))!=keccak256(user))
			{
				emit  Initiate_arbitration(-5,user,t_id);
				return -5;
			}
		}
		if(entry.getInt("state")!=1)
		{
		emit  Initiate_arbitration(-2,user,t_id);
			return -2;
		
		}
		
		
		
		Entry entry0=table_transaction.newEntry();
			entry0=entry;
			entry0.set("state",int256(0));				
			entry0.set("transaction_reason",transaction_reason);
		int256 count=table_transaction.update("key",entry0,condition);
		if(count!=1)
		{
			emit Initiate_arbitration(-3,user,t_id);
			return -3;
		}
		
		emit Initiate_arbitration(0,user,t_id);
		return 0;
		
	}
		
		
	
	
}
	
	
	
	
	
	
	
	





