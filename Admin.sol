pragma solidity ^0.4.24;

import "./Table.sol";

contract Admin {
    //admin智能合约用来进行系统操作，比如创建用户，处理仲裁信息。
    // event
    event RegisterEvent(int256 ret, string account, uint256 asset_value , int256 state, string info);
    event LogIn(int256 ret,string id );
    event LogOut(int256 ret,string id);
    event DealArbitration(int256 ret, int256 id);
    event TransferEvent(int256 ret, string from_account, string to_account, uint256 amount);
	//登陆注销的时间未设置用999表示默认

	
    constructor() public {
        // 构造函数中创建t_task4表
        createTable();
    }
	
    function createTable() private {
        TableFactory tf = TableFactory(0x1001);
        // 用户表
		// 状态 1是在线 ， 0是注销
		// |---------------------|-------------------|-----------|---------|------------|
        // |      用户主键       |       密码        |    简介   |   状态  |    余额    |
        // |-------------------- |-------------------|-----------|---------|------------|
        // |        id           |        psd        |    info   |   state |    balance |
        // |---------------------|-------------------|-----------|---------|------------|
        //
        // 创建表
        tf.createTable("t_user", "id", "psd,info,state,balance");
		
		//仲裁表
		// |---------------------|-------------------|
        // |      仲裁主键       |       简介        | 
        // |-------------------- |-------------------|
        // |        id           |        info       |  state|rid
        // |---------------------|-------------------|
        //
        // 创建表
		//State表示当前交易的状态state=0表示发起仲裁，state=1表示完成交易
        tf.createTable("t_transaction", "id", "user_sell,user_buy,commodity_id,price,descr,rid,state");
		
		//商品表
		// |---------------------|-------------------|
        // |      主键           |       简介        | 
        // |-------------------- |-------------------|
        // |   id全都是“key”     |        info       |   rid |state|owner
        // |---------------------|-------------------|
        //
        // 创建表
		//state 1为上架，0为下架,-1为删除
		//这里的id只是为了能够方便选取设置的真正的id在commodity_info.id
        tf.createTable("t_commodity", "id", "name,price,picture,descr,owner,state,rid");
		
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
	
	
	
    
    function select_user(string account) public constant returns(int256, uint256,int256,string) {
        // 打开表
        Table table = open_user_table();
        // 查询选取主键
        Entries entries = table.select(account, table.newCondition());
        uint256 balance = 0;
        if (0 == uint256(entries.size())) {
            return (-1, balance,4," ");
        } else {
            Entry entry = entries.get(0);
            return (0, uint256(entry.getInt("balance")),int256(entry.getInt("state")),string(entry.getString("info")));
        }
    }
	
	
	
	
    
    function create_user(string id, string psd, uint256 balance, string info ) public returns(int256){
        int256 ret_code = 0;
        int256 ret= 0;
        uint256 temp_asset_value = 0;
		int256 ini_state=0;
        int256 cur_state=0;
	 string memory cur_info;
        // 查询账户是否存在
        (ret, temp_asset_value,cur_state,cur_info) = select_user(id);
        if(ret != 0) {
            Table table = open_user_table();

            Entry entry = table.newEntry();
            entry.set("id", id);
            entry.set("psd", psd);
			entry.set("state", int256(ini_state));
			entry.set("info", string(info));
			entry.set("balance", uint256(balance));
            // 插入
            int count = table.insert(id, entry);
            if (count == 1) {
                // 成功
                ret_code = 0;
            } else {
                // 失败? 无权限或者其他错误
                ret_code = -2;
            }
        } else {
            // 账户已存在
            ret_code = -1;
        }

        emit RegisterEvent(ret_code, id, balance,ini_state,info);

        return ret_code;
    }
	
	
	//验证密码是否正确
	//返回1正确，其他不正确
	function valid_psd(string user,string psd) public returns(int256)
	{
	int256 ret=1;
	 Table table = open_user_table();
        // 查询选取主键
        Entries entries = table.select(user, table.newCondition());
        uint256 balance = 0;
		//用户不存在
        if (0 == uint256(entries.size())) {
	   ret=-1;
           return -1;	
        } 
		//判断密码
        Entry entry = entries.get(0);

	if(keccak256(psd)!= keccak256(entry.getString("psd")))
	{
	//密码错误
	ret=-2;
	return -2;
	}
	return ret;

	
	
	}
	
	/* 
	    1表示成功登陆
	   -1表示用户不存在
	   -2表示密码错误
	   -3表示用户已经登陆
	
	*/
	function login(string id, string psd ) public returns(int256)
	{
		 int256 ret_code = 1;
		
		
		 // 打开表
        Table table = open_user_table();
        // 查询选取主键
        Entries entries = table.select(id, table.newCondition());
        uint256 balance = 0;
		//用户不存在
        if (0 == uint256(entries.size())) {
            ret_code=-1;
			
        } else {
		//判断密码
            Entry entry = entries.get(0);

			if(keccak256(psd)!= keccak256(entry.getString("psd")))
			{
			//密码错误
			ret_code=-2;
			}
			else{
			//判断当前状态
			if(int256(entry.getInt("state"))==1){
			ret_code=-3;
			//已经登陆
			}
			else{
			Entry entry0 = table.newEntry();
            entry0.set("id", id);
            entry0.set("balance", int256(entry.getInt("balance")));
			entry0.set("psd", string(entry.getString("psd")));
			entry0.set("info", string(entry.getString("info")));
			entry0.set("state",int256(1));
            // 更新转账账户
            int count = table.update(id, entry0, table.newCondition());
			
			}
        }
		
		}
		
        emit LogIn(ret_code,id);

        return ret_code;
	}
	
	/* 
	    1表示成功登陆
	   -1表示用户不存在
	   -2表示用户已经登陆
	
	*/
	function logout(string id ) public returns(int256)
	{
		 int256 ret_code = 1;	
		 // 打开表
        Table table = open_user_table();
        // 查询选取主键
        Entries entries = table.select(id, table.newCondition());
        uint256 balance = 0;
		//用户不存在
        if (0 == uint256(entries.size())) {
            ret_code=-1;
			
        } else {
			Entry entry = entries.get(0);
			//判断当前状态
			if(int256(entry.getInt("state"))==0){
				ret_code=-2;
				//已经注销
			}
			else{
			Entry entry0 = table.newEntry();
            entry0.set("id", id);
            entry0.set("balance", int256(entry.getInt("balance")));
			entry0.set("psd", string(entry.getString("psd")));
			entry0.set("info", string(entry.getString("info")));
			entry0.set("state",int256(0));
            // 更新
            int count = table.update(id, entry0, table.newCondition());
			
			
        }
		
	}
		
        emit LogOut(ret_code,id);

        return ret_code;
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
		
		
		
		
	

	
	
	
	//处理仲裁列表中的事件
	//0成功处理仲裁
	//-1不存在对应交易记录
	//-2转账出问题
	//-3状态修改失败	
	function deal_arbitration(int256 t_id) public returns(int256)
	{
		Table table_transaction=open_transaction_table();
		Condition condition=table_transaction.newCondition();
		condition.EQ("rid",t_id);
		Entries entries=table_transaction.select("key",condition);
		if(entries.size()==0)
		{
			emit DealArbitration(-1,t_id);
			return -1;
		
		}
		Entry entry=entries.get(0);
		
		int256 result=transfer(entry.getString("user_sell"),entry.getString("user_buy"),uint256(entry.getInt("price")));
		if(result!=0)
		{
			emit DealArbitration(-2,t_id);
			return -2;
		}
		
		Entry entry0=table_transaction.newEntry();
		//entry0.set("rid",int256(t_id));
		//entry0.set("id",string("key"));
		entry0.set("state",int256(-1));
		int256 count=table_transaction.update("key",entry0,condition);
		if(count!=1)
		{
			emit DealArbitration(-3,t_id);
			return -3;
		}
		Table table_commodity=open_commodity_table();
		Entry entry1=table_commodity.newEntry();
		entry1.set("owner",entry.getString("user_sell"));
		entry1.set("state",int256(1));
		Condition condition1 = table_commodity.newCondition();
		condition1.EQ("rid", entry.getInt("commodity_id"));
			
		result=table_commodity.update("key",entry1,condition1);
		if(result!=1)
		{
				 DealArbitration(-4,t_id);
				return -4;
		}
		
		
		emit DealArbitration(0,t_id);
		return 0;
	
	}
	
}




