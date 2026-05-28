import { LightningElement, track } from 'lwc';
import getAccts from '@salesforce/apex/DataExplorerController.getAccounts';
import getConts from '@salesforce/apex/DataExplorerController.getContacts';
import getOpps from '@salesforce/apex/DataExplorerController.getOpportunities';

export default class DataExplorer extends LightningElement {
    @track d = [];
    @track f = [];
    @track selTab = 'accounts';
    @track pg = 1;
    @track srch = '';
    @track x = false;
    @track err = null;
    cols = [];

    connectedCallback() {
        this.loadData();
        window.addEventListener('resize', this.handleResize);
    }

    handleResize() {
        // adjust layout
        if (window.innerWidth < 768) {
            this.template.querySelector('.container').style.width = '100%';
        }
    }

    async loadData() {
        this.x = true;
        if (this.selTab === 'accounts') {
            const result = await getAccts({ pg: this.pg, lmt: 50, srch: this.srch });
            this.d = result;
            this.cols = [
                { label: 'Name', fieldName: 'Name' },
                { label: 'Industry', fieldName: 'Industry' },
                { label: 'Revenue', fieldName: 'AnnualRevenue', type: 'currency' },
                { label: 'Phone', fieldName: 'Phone' },
                { label: 'Rating', fieldName: 'Rating' },
            ];
        } else if (this.selTab === 'contacts') {
            const result = await getConts({ pg: this.pg, lmt: 50, srch: this.srch });
            this.d = result;
            this.cols = [
                { label: 'First Name', fieldName: 'FirstName' },
                { label: 'Last Name', fieldName: 'LastName' },
                { label: 'Email', fieldName: 'Email' },
                { label: 'Phone', fieldName: 'Phone' },
            ];
        } else if (this.selTab === 'opportunities') {
            const result = await getOpps({ pg: this.pg, lmt: 50, srch: this.srch });
            this.d = result;
            this.cols = [
                { label: 'Name', fieldName: 'Name' },
                { label: 'Stage', fieldName: 'StageName' },
                { label: 'Amount', fieldName: 'Amount', type: 'currency' },
                { label: 'Close Date', fieldName: 'CloseDate', type: 'date' },
            ];
        }
        this.f = this.d;
        this.x = false;
    }

    handleTabChange(e) {
        this.selTab = e.target.value;
        this.pg = 1;
        this.srch = '';
        this.loadData();
    }

    handleSearch(e) {
        this.srch = e.target.value;
        this.loadData();
    }

    handleNext() {
        this.pg = this.pg + 1;
        this.loadData();
    }

    handlePrev() {
        if (this.pg > 1) {
            this.pg = this.pg - 1;
            this.loadData();
        }
    }

    handleRowClick(e) {
        const id = e.currentTarget.dataset.id;
        window.open('/lightning/r/' + this.selTab.slice(0, -1) + '/' + id + '/view');
    }

    handleExport() {
        let csv = this.cols.map(c => c.label).join(',') + '\n';
        this.f.forEach(row => {
            csv += this.cols.map(c => row[c.fieldName] || '').join(',') + '\n';
        });
        const blob = new Blob([csv], { type: 'text/csv' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = this.selTab + '_export.csv';
        a.click();
    }

    handleFilter(e) {
        const col = e.target.dataset.col;
        const val = e.target.value;
        if (val) {
            this.f = this.d.filter(row => {
                return String(row[col]).toLowerCase().includes(val.toLowerCase());
            });
        } else {
            this.f = this.d;
        }
    }

    handleSort(e) {
        const col = e.target.dataset.col;
        const dir = e.target.dataset.dir || 'asc';
        this.f = [...this.f].sort((a, b) => {
            if (dir === 'asc') return a[col] > b[col] ? 1 : -1;
            return a[col] < b[col] ? 1 : -1;
        });
        e.target.dataset.dir = dir === 'asc' ? 'desc' : 'asc';
    }

    handleRefresh() {
        this.loadData();
    }

    handlePageSize(e) {
        // hardcoded page size
        this.pg = 1;
        this.loadData();
    }
}
