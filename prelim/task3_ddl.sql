CREATE DATABASE toolshare_prelim;
USE toolshare_prelim;

CREATE TABLE storage_location (
    location_code VARCHAR(10)  NOT NULL,
    description   VARCHAR(100) NOT NULL,
    PRIMARY KEY (location_code)
) ENGINE=InnoDB;

CREATE TABLE member (
    member_id   INT          NOT NULL,
    member_name VARCHAR(100) NOT NULL,
    phone       VARCHAR(20),
    join_date   DATE         NOT NULL,
    PRIMARY KEY (member_id)
) ENGINE=InnoDB;

CREATE TABLE certification (
    cert_id   INT          NOT NULL,
    cert_name VARCHAR(100) NOT NULL,
    PRIMARY KEY (cert_id)
) ENGINE=InnoDB;

CREATE TABLE tool (
    tool_id       INT          NOT NULL,
    tool_name     VARCHAR(100) NOT NULL,
    category      VARCHAR(50)  NOT NULL,
    purchase_date DATE         NOT NULL,
    location_code VARCHAR(10)  NOT NULL,
    PRIMARY KEY (tool_id),
    CONSTRAINT fk_tool_location
        FOREIGN KEY (location_code) REFERENCES storage_location (location_code)
) ENGINE=InnoDB;

CREATE TABLE tool_requirement (
    tool_id INT NOT NULL,
    cert_id INT NOT NULL,
    PRIMARY KEY (tool_id, cert_id),
    CONSTRAINT fk_req_tool FOREIGN KEY (tool_id) REFERENCES tool (tool_id),
    CONSTRAINT fk_req_cert FOREIGN KEY (cert_id) REFERENCES certification (cert_id)
) ENGINE=InnoDB;

CREATE TABLE member_certification (
    member_id       INT  NOT NULL,
    cert_id         INT  NOT NULL,
    completion_date DATE NOT NULL,
    PRIMARY KEY (member_id, cert_id),
    CONSTRAINT fk_mc_member FOREIGN KEY (member_id) REFERENCES member (member_id),
    CONSTRAINT fk_mc_cert   FOREIGN KEY (cert_id)   REFERENCES certification (cert_id)
) ENGINE=InnoDB;

CREATE TABLE borrowing (
    borrow_id   INT  NOT NULL,
    member_id   INT  NOT NULL,
    tool_id     INT  NOT NULL,
    borrow_date DATE NOT NULL,
    return_date DATE NULL,
    PRIMARY KEY (borrow_id),
    CONSTRAINT fk_borrow_member FOREIGN KEY (member_id) REFERENCES member (member_id),
    CONSTRAINT fk_borrow_tool   FOREIGN KEY (tool_id)   REFERENCES tool (tool_id)
) ENGINE=InnoDB;